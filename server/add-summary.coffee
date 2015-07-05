npmCount= require 'npm-count'

# Add calculate summary to author.json for ./top
module.exports= (normalized)->
  calculated= npmCount.calculate normalized
  normalized.package= Object.keys(calculated.packages).length

  normalized.total= calculated.total
  normalized.average= calculated.average

  normalized.weekly=
    total: calculated.weekly[0].total
    average: calculated.weekly[0].average
    rank: (
      for pkg in calculated.packages
        {name}= pkg
        {total,average}= pkg.weekly[0]

        {name,total,average}
    )
    .sort (a,b)->
      switch
        when a.total > b.total then -1
        when a.total < b.total then 1
        else 0

  normalized.monthly=
    total: calculated.monthly[0].total
    average: calculated.monthly[0].average
    rank: (
      for pkg in calculated.packages
        {name}= pkg
        {total,average}= pkg.monthly[0]

        {name,total,average}
    )
    .sort (a,b)->
      switch
        when a.total > b.total then -1
        when a.total < b.total then 1
        else 0

  normalized.yearly=
    total: calculated.yearly[0].total
    average: calculated.yearly[0].average
    rank: (
      for pkg in calculated.packages
        {name}= pkg
        {total,average}= pkg.yearly[0]

        {name,total,average}
    )
    .sort (a,b)->
      switch
        when a.total > b.total then -1
        when a.total < b.total then 1
        else 0

  normalized
