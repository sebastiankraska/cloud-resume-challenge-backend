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

    return request;
}
