
#早饭安排
class BreakfastSet
  include Mongoid::Document
  #当天早饭菜种类
  #[id:menuid]
  field :arr, type: Array, default: []
  field :date, type: Date
  
end