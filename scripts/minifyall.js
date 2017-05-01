"use strict"

const fs = require("fs")
const path = require("path")

const htmlmin = require("html-minifier").minify;
const w = require(path.join(__dirname, "w.js"))

const hopt = {
  collapseBooleanAttributes: true,
  collapseWhitespace: true,
  decodeEntities: true,
  html5: true,
  minifyCSS: true,
  minifyJS: true,
  quoteCharacter: '"',
  removeAttributeQuotes: true,
  removeComments: true,
  removeOptionalTags: true,
  removeRedundantAttributes: true,
  removeScriptTypeAttributes: true,
  removeStyleLinkTypeAttributes: true,
  useShortDoctype: true
}

const cluster = require('cluster');
const numCPUs = require('os').cpus().length;

function processFile(f, next) {
  const p = path.join(process.argv[2], f);
  i++
  hopt.minifyURLs = function (url) {
    if (url.startsWith("#")) return url;
    if (url.startsWith("http://localhost:43110/git.mkg20001.bit/")) return url.replace("http://localhost:43110", "")
    if (url.endsWith("favicon.png") || url.endsWith("style.css") || url.endsWith("logo.png")) return "../../" + url
    return url
  }
  fs.readFile(p, (e, c) => {
    if (e) return next(e)
    try {
      fs.writeFile(p, new Buffer(htmlmin(c.toString(), hopt).replace("http://localhost:43110/git.mkg20001.bit/", "/git.mkg20001.bit/")), next)
    } catch (e) {
      next(e)
    }
  })
}

function eachWorker(callback) {
  for (var id in cluster.workers) {
    callback(cluster.workers[id]);
  }
}

if (cluster.isMaster) {
  var files = fs.readFileSync(path.join(__dirname, "files")).toString().split("\n").filter((r) => {
    return !!r;
  })
  const _length = files.length;
  // Fork workers.
  for (var i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  var ii = 0;
  var working = 0;
  cluster.on("message", (w, msg) => {
    if (msg != "first") working--
  })
  let l = 0
  w(files, (f, next) => {
    cluster.once('message', (worker /*,msg*/ ) => {
      ii++
      working++
      if (new Date().getTime() - l > 100 || ii === _length) {
        console.log("[%s|%s/%s] Process\t(%s/%s)\t%s...", worker.id, working, numCPUs, ii, _length, f)
        l = new Date().getTime()
      }
      worker.send("file:" + f)
      next()
    });
  })((e) => {
    if (e) {
      console.error("E: " + e.toString())
      process.exit(2)
    }
    var si = setInterval(() => {
      if (working) console.log("Waiting for %s more worker(s) to finish...", working);
      else clearInterval(si)
    }, 100)
    eachWorker((worker) => {
      worker.send('end');
    });
    cluster.on("message", (worker) => {
      worker.send("end")
    })
  })
} else {
  var running = false
  process.on('message', (msg) => {
    if (msg.startsWith("file")) {
      running = true
      processFile(msg.split(":").slice(1).join(":"), (e) => {
        if (e) console.error("E: " + e.toString())
        running = false
        process.send("ready")
      })
    } else if (msg == "end") {
      if (!running) process.exit(0)
    }
  });
  process.send("first")
}
