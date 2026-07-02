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

    // If the request has no file extension (clean URL like /tags),
    // rewrite to /tags/index.html — Quartz generates directory-style pages
    else if (!uri.split("/").pop().includes(".")) {
        request.uri += "/index.html";
    }

    return request;
}
