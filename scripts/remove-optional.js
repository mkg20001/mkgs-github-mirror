const c = require(process.argv[2])
const fs = require("fs")
const path = require("path")
const d = path.dirname(process.argv[2])
Object.keys(c.files_optional).filter(p => !fs.existsSync(path.join(d, p))).map(p => {
  console.log("Clear old %s...", p)
  delete c.files_optional[p]
})
fs.writeFileSync(process.argv[2], new Buffer(JSON.stringify(c, null, 2)))
