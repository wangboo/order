
class Meal
  include Mongoid::Document
  field :date,    type: Date
  #0 早餐，1午餐，2晚餐
  field :kind,    type: Integer
  field :userId,  type: String
#   早饭时，使用该字段所点的菜
#   [{id: menu编号, name: 菜名, count: n}]
  field :order,   type: Array
  #午饭时使用，eat表示吃几份
  field :eat,     type: Integer, default: 1
end