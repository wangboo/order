
class User
  include Mongoid::Document
  field :cardId,  type: String
  field :name,    type: String
  field :pwd,     type: String
  #0 用户，1食堂管理员（暂时不用），2管理员
  field :kind,    type: Integer
  field :icon,    type: String
  field :valid,   type: Boolean, default: true
end