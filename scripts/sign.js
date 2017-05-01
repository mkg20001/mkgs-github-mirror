const zeroFrame = require(__dirname + "/zero-frame")
const url = require(__dirname + "/url-formatter")
const zite = "1F7b27kT38nMYZQg7tvDr33qWDZQgwnQpw"
console.log(" => Connect to localhost as %s", zite)
zeroFrame(url("http://127.0.0.1:43110/" + zite), (e, z) => {
  if (e) throw e
  console.log(" => Connected")
  console.log("    => siteSign")
  z.cmd("siteSign", ["stored", "content.json"], e => {
    if (e) throw e
    console.log("   => sitePublish")
    z.cmd("sitePublish", ["stored", "content.json", false],e => {
      if (e) throw e
      console.log(" => OK")
      process.exit(0)
    })
  })
})
