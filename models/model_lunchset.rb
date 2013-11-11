
#午饭安排
class LunchSet
  include Mongoid::Document
  #当天午饭菜种类
  #[id(menuId),id]
  field :arr, type: Array, default: []
  field :date, type: Date
end