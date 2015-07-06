# Dependencies
path= require 'path'
root= path.resolve '__dirname','..'

# Environment
process.env.ROOT= root+path.sep
process.env.DB= root+path.sep+'db'+path.sep
process.env.SERVER= root+path.sep+'server'+path.sep
process.env.CLIENT= root+path.sep+'client'+path.sep

module.exports= process.env
