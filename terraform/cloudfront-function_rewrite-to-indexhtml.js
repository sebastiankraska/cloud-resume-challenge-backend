// Extensions that map directly to S3 objects without a .html suffix.
var STATIC_EXTENSIONS = [
    ".css", ".js", ".html", ".xml", ".json", ".svg",
    ".png", ".jpg", ".jpeg", ".webp", ".gif", ".ico",
    ".woff", ".woff2", ".ttf", ".eot", ".otf",
    ".mp4", ".webm", ".ogg", ".mp3",
    ".pdf", ".zip", ".txt", ".map",
];

function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri.endsWith("/")) {
        request.uri += "index.html";
    }
    else if (uri === "") {
        request.uri = "/index.html";
    }
    else {
        var lastSegment = uri.split("/").pop();
        var dotIndex = lastSegment.lastIndexOf(".");
        var ext = dotIndex >= 0 ? lastSegment.slice(dotIndex) : "";
        var isStaticAsset = false;
        for (var i = 0; i < STATIC_EXTENSIONS.length; i++) {
            if (ext === STATIC_EXTENSIONS[i]) { isStaticAsset = true; break; }
        }
        if (!isStaticAsset) {
            // Quartz taxonomy pages (tags/*) use directory-style index.html.
            // All other non-static paths (including .base) are flat .html files.
            var isDirectoryPath = uri === "/tags" || uri.startsWith("/tags/");
            request.uri += isDirectoryPath ? "/index.html" : ".html";
        }
    }

    return request;
}
