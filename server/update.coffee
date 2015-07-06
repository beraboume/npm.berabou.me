# Dependencies
npmCount= require 'npm-count'

Promise= require 'bluebird'
npmFetchAvatar= Promise.promisify(require 'npm-fetch-avatar')
fs= Promise.promisifyAll(require 'fs')

addSummary= require './add-summary'

# Public
module.exports= (author,authorPath)->
  delete require.cache[authorPath]

  npmCount.fetch author,'all'
  .then (packages)->
    if Object.keys(packages).length
      npmCount.normalize packages
    else
      Promise.resolve null

  .then (normalized)->
    return null unless normalized

    normalized.author= author

    npmFetchAvatar author
    .then (avatar)->
      normalized.avatar= avatar

      normalized= addSummary normalized
      fs.writeFileAsync authorPath,(JSON.stringify normalized)
      .then ->
        normalized
