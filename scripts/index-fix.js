const fs=require("fs")

re=/\"([a-z0-9.-]+)\/log\.html\"/gmi

c=fs.readFileSync(process.argv[2]).toString()

e=c.replace(re,"\"$1.tar.gz/$1/log.html\"")

fs.writeFileSync(process.argv[2],new Buffer(e))
