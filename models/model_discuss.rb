#评论
class Discuss
  include Mongoid::Document
  #序号=年*12+月
  field :index, type: Integer
  #用户id
  field :userId, type: String
  #服务态度
  field :attitude, type: Integer, default: 0
  #菜品质量
  field :quality, type: Integer, default: 0
  #卫生情况
  field :health, type: Integer, default: 0
  #附言
  field :extra, type: String, default: ""
end