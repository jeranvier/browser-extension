window.mem0r1es = {} if not window.mem0r1es?
window.IDBKeyRange =window.IDBKeyRange or window.webkitIDBKeyRange or window.mozIDBKeyRange or window.msIDBKeyRange

class window.mem0r1es.Query
  constructor : () ->
    @andConditions = new Array
  
  from : (@storeName) ->
    return @
  
  #tranform an (in)equality on a key into a keyrange object
  where : (@key, inequality, firstBound, firstOpen = false, secondBound, secondOpen = false ) ->
    switch inequality
      when "equals"
        @keyRange = IDBKeyRange.only firstBound
        @ICondition = "#{@key}=#{firstBound}"
      when "greaterThan"
        @keyRange = IDBKeyRange.lowerBound firstBound, firstOpen
        @ICondition = "#{@key}>#{if not firstOpen then "=" else ""}#{firstBound}"
      when "lowerThan"
        @keyRange = IDBKeyRange.upperBound firstBound, firstOpen
        @ICondition = "#{@key}<#{if not firstOpen then "=" else ""}#{firstBound}"
      when "between"
        @keyRange = IDBKeyRange.bound firstBound, secondBound, firstOpen, secondOpen
        @ICondition = "#{firstBound}<#{if not firstOpen then "=" else ""}#{@key}<#{if not secondOpen then "=" else ""}#{secondBound}"
    return @
    
  and : (key, inequality, firstBound, firstOpen = false, secondBound, secondOpen = false)->
    switch inequality
      when "equals"
        @andConditions.push "candidate.#{key}==#{firstBound}"
      when "greaterThan"
        @andConditions.push "candidate.#{key}>#{if not firstOpen then "=" else ""}#{firstBound}"
      when "lowerThan"
        @andConditions.push "candidate.#{key}<#{if not firstOpen then "=" else ""}#{firstBound}"
      when "between"
        @andConditions.push "#{firstBound}<#{if not firstOpen then "=" else ""}candidate.#{key}<#{if not secondOpen then "=" else ""}#{secondBound}"
    return @
    
  accept : (candidate) ->
    for condition in @andConditions
      if not eval(condition)
        return false
    return true
      
  
  toString : () ->
    string = "SELECT object FROM #{@storeName} WHERE #{@ICondition}"
    for andCondition in @andConditions
      string = "#{string} AND #{andCondition}"
    return string