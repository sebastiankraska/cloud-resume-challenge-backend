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

    // If the request has no file extension (clean URL like /tags/meta),
    // rewrite to /tags/meta.html
    // Quartz generates flat .html files, not nested index.html like Hugo
    else if (!uri.split("/").pop().includes(".")) {
        request.uri += ".html";
    }

    return request;
}
