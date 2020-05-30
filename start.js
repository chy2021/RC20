var http = require('http');
var fs = require('fs');
var url = require('url');
const {exec} = require("child_process");
var port = 8080;
var urlStr = "http://localhost:" + port;

// 创建服务器
http.createServer( function (request, response) {
    // 解析请求，包括文件名
    var pathname = url.parse(request.url).pathname;

    // 输出请求的文件名
    if (pathname == '/') {
        pathname = "/index.html";
    }

    // 从文件系统中读取请求的文件内容
    fs.readFile(pathname.substr(1), function (err, data) {
        if (err) {
            console.log(err);
            // HTTP 状态码: 404 : NOT FOUND
            // Content Type: text/html
            response.writeHead(404, {'Content-Type': 'text/html'});
        }else{
            // HTTP 状态码: 200 : OK
            // Content Type: text/html
            response.writeHead(200, {'Content-Type': 'text/html'});

            // 响应文件内容
            response.write(data.toString());
        }
        //  发送响应数据
        response.end();
    });

}).listen(port);

switch (process.platform) {
    //mac系统使用 一下命令打开url在浏览器
    case "darwin":
        exec(`open ${urlStr}`);
    //win系统使用 一下命令打开url在浏览器
    case "win32":
        exec(`start ${urlStr}`);
    // 默认mac系统
    default:
        exec(`open ${urlStr}`);
}

// 控制台会输出以下信息
console.log('Server running at ' + urlStr);