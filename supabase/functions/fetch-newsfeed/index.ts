// supabase/functions/fetch-newsfeed/index.ts
//
// Fetches RSS feeds from a set of free, public health/fitness sources,
// parses them, and upserts new articles into the `newsfeed_items` table.
// Designed to run once a day via Supabase's pg_cron scheduler.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { parseFeed } from "https://deno.land/x/rss@1.0.0/mod.ts";

// Map each RSS feed to one of your app's existing categories:
// Health, Nutrition, Fitness, Gym, Yoga
const FEEDS: { url: string; category: string; source: string }[] = [
  {
    url: "https://www.healthline.com/rss/health-news",
    category: "Health",
    source: "Healthline",
  },
  {
    url: "https://www.eatthis.com/feed/",
    category: "Nutrition",
    source: "Eat This, Not That",
  },
  {
    url: "https://breakingmuscle.com/feed/",
    category: "Fitness",
    source: "Breaking Muscle",
  },
  {
    url: "https://www.yogajournal.com/feed/",
    category: "Yoga",
    source: "Yoga Journal",
  },
  {
    url: "https://breakingmuscle.com/feed/",
    category: "Gym",
    source: "Breaking Muscle",
  },
];

serve(async (_req) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, supabaseKey);

  let totalInserted = 0;
  const errors: string[] = [];

  for (const feed of FEEDS) {
    try {
      const res = await fetch(feed.url, {
        headers: { "User-Agent": "GetFitApp/1.0 (RSS Reader)" },
      });
      const xml = await res.text();
      const parsed = await parseFeed(xml);

      const imageMap = extractImageMapFromXml(xml);

      const rows = await Promise.all(parsed.entries.slice(0, 15).map(async (entry) => {
        const link = entry.links?.[0]?.href ?? entry.id ?? "";
        const rawContent = (entry as any)["content"]?.value ?? "";
        let image =
          entry.attachments?.[0]?.url ??
          imageMap.get(link) ??
          extractImageFromHtml(entry.description?.value ?? "") ??
          extractImageFromHtml(rawContent) ??
          null;

        // Last resort: fetch the article page itself and read its og:image tag.
        if (!image && link) {
          image = await fetchOgImage(link);
        }

        // Breaking Muscle (and similar WP/Cloudflare sites) block hotlinked
        // image requests from the Flutter app with a 403, even with spoofed
        // headers. So instead of storing their URL directly, we download the
        // image server-side here and re-host it in Supabase Storage.
        if (image && image.includes("breakingmuscle.com")) {
          const rehosted = await rehostImage(supabase, image);
          if (rehosted) image = rehosted;
        }

        return {
          title: decodeAndStripHtml(entry.title?.value ?? "Untitled"),
          description: decodeAndStripHtml(entry.description?.value ?? "").slice(0, 300),
          image_url: image,
          category: feed.category,
          author: entry.author?.name ?? feed.source,
          source_name: feed.source,
          source_url: link,
          published_at: entry.published?.toISOString() ??
            entry.updated?.toISOString() ??
            new Date().toISOString(),
        };
      })).then((r) => r.filter((row) => row.source_url));

      if (rows.length > 0) {
        const { error } = await supabase
          .from("newsfeed_items")
          .upsert(rows, { onConflict: "source_url,category", ignoreDuplicates: false })
          .select("id");

        if (error) {
          errors.push(`${feed.source}: ${error.message}`);
        } else {
          totalInserted += rows.length;
        }
      }
    } catch (e) {
      errors.push(`${feed.source}: ${(e as Error).message}`);
    }
  }

  // Optional: trim table to keep only the most recent 300 articles overall,
  // so it doesn't grow forever.
  try {
    await supabase.rpc("trim_newsfeed_items", { keep_count: 300 });
  } catch (_) {
    // ignore if the function doesn't exist yet
  }

  return new Response(
    JSON.stringify({ processed: FEEDS.length, totalInserted, errors }),
    { headers: { "Content-Type": "application/json" } },
  );
});

function stripHtml(html: string): string {
  return html.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
}

// Decodes common HTML entities (handles double-encoded tags like
// "&lt;i&gt;Dutton Ranch&lt;/i&gt;") then strips any real tags left over.
function decodeAndStripHtml(html: string): string {
  const decoded = html
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#0?39;/g, "'");
  return stripHtml(decoded);
}

// Fetches an article's HTML page and extracts the og:image meta tag.
// Used as a last-resort fallback when a feed's RSS/XML has no image at all
// (common with WordPress block-themes like Breaking Muscle).
async function fetchOgImage(url: string): Promise<string | null> {
  try {
    const res = await fetch(url, {
      headers: { "User-Agent": "GetFitApp/1.0 (RSS Reader)" },
      signal: AbortSignal.timeout(5000),
    });
    const html = await res.text();
    const match =
      html.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i) ??
      html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i);
    return match?.[1] ?? null;
  } catch {
    return null;
  }
}

// Downloads an image server-side and re-uploads it to Supabase Storage,
// returning the new public URL. Used for sources (like Breaking Muscle)
// that 403 direct hotlink requests from the mobile app.
async function rehostImage(
  supabase: ReturnType<typeof createClient>,
  imageUrl: string,
): Promise<string | null> {
  try {
    const res = await fetch(imageUrl, {
      headers: {
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Referer": "https://breakingmuscle.com/",
      },
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) return null;

    const bytes = new Uint8Array(await res.arrayBuffer());
    const ext = imageUrl.split(".").pop()?.split("?")[0] ?? "webp";
    const fileName = `bm-${crypto.randomUUID()}.${ext}`;
    const contentType = res.headers.get("content-type") ?? "image/webp";

    const { error } = await supabase.storage
      .from("newsfeed-images")
      .upload(fileName, bytes, { contentType, upsert: true });
    if (error) {
      console.error("rehostImage upload error:", error.message);
      return null;
    }

    const { data } = supabase.storage
      .from("newsfeed-images")
      .getPublicUrl(fileName);
    return data.publicUrl;
  } catch (e) {
    console.error("rehostImage failed:", (e as Error).message);
    return null;
  }
}

function extractImageFromHtml(html: string): string | null {
  const match = html.match(/<img[^>]+src="([^">]+)"/);
  return match ? match[1] : null;
}

// Reads an attribute value regardless of quote style (' or ") or order.
function getAttr(tag: string, attr: string): string | null {
  const match = tag.match(new RegExp(`${attr}\\s*=\\s*["']([^"']+)["']`, "i"));
  return match ? match[1] : null;
}

function extractImageMapFromXml(xml: string): Map<string, string> {
  const map = new Map<string, string>();
  const itemBlocks = xml.match(/<item[\s\S]*?<\/item>/g) ??
    xml.match(/<entry[\s\S]*?<\/entry>/g) ?? [];

  for (const block of itemBlocks) {
    const linkMatch = block.match(/<link>([\s\S]*?)<\/link>/) ??
      block.match(/<link[^>]+href=["']([^"']+)["']/);
    const link = linkMatch?.[1]?.trim();
    if (!link) continue;

    let image: string | null = null;

    // media:content / media:thumbnail (any attribute order)
    const mediaTag = block.match(/<media:content[^>]*\/?>/i)?.[0] ??
      block.match(/<media:thumbnail[^>]*\/?>/i)?.[0];
    if (mediaTag) image = getAttr(mediaTag, "url");

    // enclosure with type=image (any attribute order)
    if (!image) {
      const enclosureTags = block.match(/<enclosure[^>]*\/?>/gi) ?? [];
      for (const tag of enclosureTags) {
        const type = getAttr(tag, "type");
        if (type && type.startsWith("image")) {
          image = getAttr(tag, "url");
          break;
        }
      }
    }

    // Inline <img> — check src, then lazy-load data-src variants
    if (!image) {
      const imgTag = block.match(/<img[^>]*>/i)?.[0];
      if (imgTag) {
        image = getAttr(imgTag, "src") ??
          getAttr(imgTag, "data-src") ??
          getAttr(imgTag, "data-lazy-src");
      }
    }

    if (image) map.set(link, image);
  }

  return map;
}