const c = require(process.argv[2])
const fs = require("fs")
c.files_optional = {}
fs.writeFileSync(process.argv[2], new Buffer(JSON.stringify(c, null, 2)))
