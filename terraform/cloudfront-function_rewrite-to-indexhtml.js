function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // If the request ends with a slash (like /about/), rewrite to /about/index.html
    if (uri.endsWith("/")) {
        request.uri += "index.html";
    }

    // If the request is just "/", serve /index.html
    else if (uri === "") {
        request.uri = "/index.html";
    }

    // Quartz taxonomy pages (tags/*) use directory-style index.html.
    // All other extensionless paths are flat .html files.
    else if (!uri.split("/").pop().includes(".")) {
        var isDirectoryPath = uri === "/tags" || uri.startsWith("/tags/");
        request.uri += isDirectoryPath ? "/index.html" : ".html";
    }

    return request;
}
