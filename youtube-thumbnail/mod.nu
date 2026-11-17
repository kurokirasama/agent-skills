# Nushell helper for youtube-thumbnail skill

# Generates metadata guidelines and safe-zone dimensions for 16:9 thumbnails
export def get-thumbnail-specs [] {
    {
        width: 1280,
        height: 720,
        aspect_ratio: "16:9",
        safe_margin_px: 60,
        timestamp_exclusion_zone: {
            x_min: 1040,
            y_min: 620,
            x_max: 1280,
            y_max: 720
        },
        max_words: 4,
        preferred_formats: ["png", "jpg", "webp"]
    }
}
