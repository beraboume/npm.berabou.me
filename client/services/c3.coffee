return unless window?

app= angular.module 'npm'

app.factory 'c3js',->
  window.c3
app.directive 'c3',(c3js)->
  scope:
    data: '=c3'
    type: '=c3Type'
    label: '=c3Label'
  link:(scope,element,attrs)->
    c3= c3js.generate
      bindto: element[0]
      data:
        columns: [
          '',0
        ]

      tooltip:
        format:
          title: (i)->
            scope.label[i] ? i
      axis:
        x:
          tick:
            format: (i)->
              day= scope.label[i] ? i
              day.split('-')?.slice(-1)
        y:
          label:
            text: 'Downloads',
            position: 'outer-middle'
          tick:
            format: d3.format ","

    scope.$watch 'data',(newVal)->
      setTimeout -># Fixed pie chart position
        c3.load newVal

    scope.$watch 'type',()->
      c3.transform scope.type
