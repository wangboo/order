#encoding: utf-8
require "mongoid"
require "yaml"
ENV["MONGOID_ENV"] = "development"
Mongoid.load!("./config/mongo.yml")
require "./mongo_addon.rb"
Dir.new("#{Dir.pwd}/models").each{|name|require "./models/#{name}" if name=~/^model_/}
#增加一个普通用户
User.all.delete
user = User.new
user.cardId = "231520"
user.pwd = "0000"
user.name = "王博"
user.kind = 0
user.save!
User.create(cardId: "admin", pwd: "admin", name: "admin", kind: 2)
User.create(cardId: "10001", pwd: "0000", name: "路人甲", kind: 0)
#增加早餐菜谱
Menu.all.delete
#早餐
b1 = Menu.create(kind: [0], unit: "个", name: "酱肉包子", desc: "食堂大叔最拿手的香喷喷的酱肉包", icon: "/image/menu_jiangrou.jpg")
b2 = Menu.create(kind: [0], unit: "个", name: "鲜肉包子", desc: "来自千喜鹤最高品质肉馅，鲜香扑鼻！", icon: "/image/menu_xianrou.jpg")
b3 = Menu.create(kind: [0], unit: "个", name: "馒头", desc: "吃不完还可以拿去当砖头用", icon: "/image/menu_mantou.jpg")
b4 = Menu.create(kind: [0], unit: "两", name: "大米粥", desc: "大米粥是中国经常食用的家常饭，特别是早餐。大米性味甘平，有和胃气、补脾虚、壮筋骨、和五脏的功效。", icon: "/image/menu_damizhou.jpg")
b5 = Menu.create(kind: [0], unit: "两", name: "面条", desc: "好吃的米粉，不多说。", icon: "/image/menu_miantiao.jpg")
#午餐
m1 = Menu.create(kind: [1], unit: "份", name: "鱼香肉丝", desc: "鱼香肉丝是一道常见川菜。鱼香，是四川菜肴主要传统味型之一。", icon: "/image/menu_yuxiangrousi.jpg")
m2 = Menu.create(kind: [1], unit: "份", name: "麻婆豆腐", desc: "麻婆豆腐是中国汉族八大菜系之一的川菜中的名品。主要原料由豆腐构成，其特色在于麻、辣、烫、香、酥、嫩、鲜、活八字，称之为八字箴言。材料主要有豆腐、牛肉碎（也可以用猪肉）、辣椒和花椒等。", icon: "/image/menu_mapodoufu.jpg")
m3 = Menu.create(kind: [1], unit: "个", name: "酱香鸡腿", desc: "好吃不腻的鸡腿，值得期待哦！", icon: "/image/menu_jiangxiangjitui.jpg")

LunchSet.all.delete
LunchSet.create(date: Time.now.tomorrow.midnight, arr: [m1.id, m2.id, m3.id])
# puts LunchSet.all

BreakfastSet.all.delete
BreakfastSet.create(date: Time.now.tomorrow.midnight, arr: [b1.id, b2.id, b3.id, b4.id, b5.id])


