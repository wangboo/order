
#  菜种类
class Menu
  include Mongoid::Document
  #0 早餐，1午餐，2晚餐
  #一种菜可以在早餐，午餐，晚餐都上
  field :kind, type: Array
  #单位
  field :unit, type: String
#   菜名
  field :name, type: String
#   菜描述
  field :desc, type: String
#   图片
  field :icon, type: String
end