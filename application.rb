#encoding: utf-8
require "mongoid"
require "sinatra/base"
require "sinatra/cookies"
require "active_support/time"
require "./mongo_addon.rb"
require "yaml"
# ENV["RACK_ENV"] = "production"
# ENV["MONGOID_ENV"] = "production"

Mongoid.load!("./config/mongo.yml")

require "./add_on.rb"
Dir.new("#{Dir.pwd}/models").each{|name|require "./models/#{name}" if name=~/^model_/}

class App < Sinatra::Base
  
  # enable :session
  use Rack::Session::Pool, :expire_after => 2592000
  helpers Sinatra::Cookies
  include AddOn
  
  before do
   path = request.path_info
   puts "path=#{path}, user=#{session[:user]}, id=#{cookies[:cardId]}, pwd=#{cookies[:pwd]}"
   return if path =~ /^\/css\// or path =~ /^\/js\// or path =~ /^\/img\//
   if session[:user]
     if session[:user].kind == 2 and (not path =~ /^\/admin/) and path != "/" and path != "/login"
       puts "非管理员账号，权限拦截"
       redirect to("/login"); 
       return 
     end
     if session[:user].kind == 0 and path =~ /^\/admin/  and path != "/" and path != "/login"
       puts "非普通用户账号，权限拦截"
       redirect to("/login"); 
       return 
     end
   end
   puts "access filter"
   if path == "/"
#      检查cookie是否存在
      cardId = cookies[:cardId]
      pwd = cookies[:pwd]
      if cardId
        #如果账号存在
        if user = login(cardId, pwd)
          #登录成功，进入对应用户的主界面
          redirect case user.kind
          when 0
            to("/index")
          when 1
            to("/mess")
          when 2
            to("/admin")
          end
          return
        else
          #登录失败，回到login
          redirect to("/login");return
        end
      else
        #账号不存在
          redirect to("/login");return
      end
      
    elsif path == "/login"
      puts "path=login 放开拦截"
    else
#       检查session，判断是否登录过
        redirect to("/login") unless session[:user]
        return
   end
  end
  
  get "/" do
    puts "get /"
    cardId = cookies[:cardId]
    pwd = cookies[:pwd]
    if user = login(cardId, pwd)
      #登录成功，进入对应用户的主界面
      redirect case user.kind
      when 0
        to("/index")
      when 1
        to("/mess")
      when 2
        to("/admin")
      end
    else
      #登录失败，回到login
      redirect to("/login")
    end
  end
  
  get "/login" do
    erb :login
  end
  
  post "/login" do
    puts "post login params=#{params}"
    cardId = params[:cardId]
    pwd = params[:pwd]
    kind = params[:kind]
    if user = login(cardId, pwd)
      puts "登陆成功"
      puts "user=#{session[:user]}, id=#{cookies[:cardId]}, pwd=#{cookies[:pwd]}"
      #登录成功，进入对应用户的主界面
      redirect case user.kind
      when 0
        to("/index")
      when 1
        to("/mess")
      when 2
        to("/admin")
      end
      return
    else
      erb :login
    end
    # frame :index, index
  end
  
  #flag 0可以点餐，10今天已经下班，不能点餐,11太早了，不营业
  get "/index" do
    frame :index, menu
  end
  
  get "/lunch" do
    frame :lunch, menu(1)
  end
  
  def menu(kind=0)
    #查询今天是否下班
    now = Time.now
    date = now.tomorrow.midnight
    #flag默认可点早、中、晚餐
    p = {flag: 0}
    if now.hour > 17
      #太晚了，不能点餐了
      p[:flag] = 10
    elsif now.hour < 6
      #太早了，不能点餐
      p[:flag] = 11
    elsif now.thursday?
      #今天是周四，今天不能点晚餐
      p[:flag] = 1
    elsif now.friday?
      #今天是周五，能点周天的晚餐,和周一的饭
      date = 3.days.since.midnight
      p[:flag] = 2
    elsif now.saturday?
      date = 2.days.since.midnight
      p[:flag] = 2
    elsif now.sunday?
      #今天是周末，可以点周一的菜
      date = 1.days.since.midnight
      p[:flag] = 3
    end
    #查询是不是点过了
    user = session[:user]
    puts "query date : #{date}"
    p[:meal] = Meal.where(userId: user.id, kind: kind, date: date).first
    case kind
    when 0
      p[:menus] = BreakfastSet.where(date: date).first
    when 1
      p[:menus] = LunchSet.where(date: date).first    
    end
    p[:select_date] = date
    #查询明天是否是周六
    #查询明天的早餐
    p
  end
  
  post "/index/order/breakfast" do
    return "请用普通账号登陆" if session[:user].kind != 0
    puts params
    menuId = params[:id]
    name = Menu.find(menuId).name
    count = params[:count]
    date = Time.at(params[:date].to_i)
    user = session[:user]
    meal = Meal.where(userId: user.id, kind: 0, date: date).first
    if meal
      #是否是更新的
       if item = meal.order.find{|o|o["id"]==menuId}
        item["count"] = count
        else
          meal.order << {id: menuId, name: name, count: count}
      end
      meal.update
    else
      order = [{id: menuId, count: count, name: name}]
      Meal.create(date: date, kind: 0, userId: user.id, order: order)
    end
    "s"
  end
  
  #定早餐
  post("/index/order/lunch") do
    return "请用普通账号登陆" if session[:user].kind != 0
    eat = params[:eat].to_i
    date = Time.at(params[:date].to_i)
    user = session[:user]
    meal = Meal.where(userId: user.id, kind: 1, date: date).first
    if meal
      meal.eat = eat
      meal.update
    else
      Meal.create(date: date, kind: 1, userId: user.id, eat: eat)
    end
    "s"
  end
  
  #查询近一周的早餐安排
  get "/set/breakfast" do
    date = nil
    if params[:date]
      date = Time.at(params[:date].to_i)
    else
      date = Time.now.midnight.tomorrow
    end
    frame :set_breakfast, {select_date: date}
  end
  
  #查询近一周的午餐安排
  get "/set/lunch" do
    date = nil
    if params[:date]
      date = Time.at(params[:date].to_i)
    else
      date = Time.now.midnight.tomorrow
    end
    frame :set_lunch, {select_date: date}
  end
  
  get "/discuss" do
    frame :discuss, {discuss: this_month_discuss[0]}
  end
  
  def this_month_discuss
    now = Time.now
    index = now.year.to_i * 12 + now.month.to_i
    discuss = Discuss.where(index: index, userId: session[:user].id).first
    if discuss
      [discuss, false]
    else
      discuss = Discuss.new(index: index, userId: session[:user].id)
      [discuss, true]
    end
  end
  
  post "/discuss" do
    discuss, create = this_month_discuss
    discuss.attitude = params[:attitude].to_i
    discuss.quality = params[:quality].to_i
    discuss.health = params[:health].to_i
    discuss.extra = params[:extra]
    if create
      discuss.save
    else
      discuss.update
    end
    frame :discuss, {discuss: discuss}
  end
  
  get "/discuss_statistics" do
    frame :discuss_statistics
  end
  
  get "/account" do
    frame :account, {user: session[:user]}
  end
  
  post "/account" do
    user = session[:user]
    user.pwd = params[:pwd]
    user.save
    frame :account, {user: session[:user], s: true}
  end
  
  get "/admin" do
    admin_frame :add_menu
  end
  
  get "/admin/menu/add" do
    admin_frame :add_menu
  end
  
  #增加菜menu
  post "/admin/menu/add" do
    puts "post /admin/menu/add params=#{params}"
    menu_set_param
    puts params
    Menu.create params
    admin_frame :add_menu
  end
  
  def menu_set_param
     kind = params[:kind]
    params[:kind] = case kind.to_i
    when 0..2
      [kind]
    when 3#早，中
      [0, 1]
    when 4#早，晚
      [0, 2]
    when 5#中，晚
      [1, 2]
    when 6#早，中，晚
      [0, 1, 2]
    else
      [0, 1, 2]
    end
    if file = params[:file]
      tempFile = file[:tempfile]
      suffix = file[:filename].gsub(/\.\w+/).first
      filename = random_img_name(suffix)
      puts filename
      File.open("./public/#{filename}", "wb+") do |f|
        f.write tempFile.read
      end
      params[:icon] = filename
      params.delete :file
      params.delete "file"
    end
  end
  
  #修改菜单页面
  get "/admin/menu/modify" do
    select = params[:select]
    breakfast = Menu.where(kind: 0)
    lunch = Menu.where(kind: 1)
    select = if select
      Menu.find select
    else
      breakfast.first
    end
    admin_frame :modify_menu, {breakfast: breakfast, lunch: lunch, select: select}
  end
  
  get "/admin/menu/delete" do
    id = params[:id]
    Menu.find(id).delete
    redirect to("/admin/menu/modify")
  end
  
  post "/admin/menu/modify" do
    menu_set_param
    select = Menu.find(params[:id])
    select.name = params[:name]
    select.icon = params[:icon] if params[:icon]
    select.kind = params[:kind]
    select.desc = params[:desc]
    select.unit = params[:unit]
    select.update
    breakfast = Menu.where(kind: 0)
    lunch = Menu.where(kind: 1)
    admin_frame :modify_menu, {s: true, breakfast: breakfast, lunch: lunch, select: select}
  end
  
  #发布早餐页面
  get "/admin/breakfast/publish" do
    date = nil
    if params[:date]
      date = Time.at(params[:date].to_i)
    else
      date = Time.now.midnight.tomorrow
    end
    puts "date #{date}"
    admin_frame :breakfast_publish, {select_date: date}
  end
  
  #向某一天早餐中增加一个菜 ajax
  post "/admin/breakfast/publish/add" do
    date = Time.at(params[:date].to_i)
    id = params[:id]
    set = BreakfastSet.where(date: date).first
    if set
      set.arr << id; set.update if set.arr.include? id
    else
      BreakfastSet.create(date: date, arr: [id])
    end
  end
  
  #向某一天早餐中删除一个菜 ajax
  post "/admin/breakfast/publish/remove" do
    date = Time.at(params[:date].to_i)
    id = params[:id]
    set = BreakfastSet.where(date: date).first
    if set
      set.arr.delete id
      set.update
    end
  end
  
  #发布午餐页面
  get "/admin/lunch/publish" do
    date = nil
    if params[:date]
      date = Time.at(params[:date].to_i)
    else
      date = Time.now.midnight.tomorrow
    end
    admin_frame :lunch_publish, {select_date: date}
  end
  
    #向某一天早餐中增加一个菜 ajax
  post "/admin/lunch/publish/add" do
    date = Time.at(params[:date].to_i)
    count = params[:count].to_i
    id = params[:id]
    set = LunchSet.where(date: date).first
    if set
      set.arr << id
      set.update
    else
      LunchSet.create(date: date, arr: [id])
    end
  end
  
  #向某一天早餐中删除一个菜 ajax
  post "/admin/lunch/publish/remove" do
    date = Time.at(params[:date].to_i)
    id = params[:id]
    set = LunchSet.where(date: date).first
    if set
      set.arr.delete_if{|item|id==item[0].to_s}
      set.update
    end
  end
  
  get "/admin/breakfast/count" do
    if params[:date]
      date = Time.at(params[:date].to_i)
    else
      date = Time.now.midnight.tomorrow
    end
    puts "get /admin/breakfast/count, date=#{date}"
    admin_frame :count_breakfast, {select_date: date}
  end
  
  get "/admin/lunch/count" do
    if params[:date]
      date = Time.at(params[:date].to_i)
    else
      date = Time.now.midnight.tomorrow
    end
    puts "get /admin/lunch/count, date=#{date}"
    admin_frame :count_lunch, {select_date: date}
  end
  
  #查看用户
  get "/admin/account" do
    select = if params[:select]
      User.find(params[:select])
    else
      User.where(kind: 0).first
    end
    admin_frame :account, {select: select}
  end
  
  #修改用户信息
  post "/admin/account/modify" do
    id = params[:id]
    name = params[:name]
    cardId = params[:cardId]
    pwd = params[:pwd]
    select = User.find(id)
    select.name = name
    select.pwd = pwd
    select.cardId = cardId
    select.save
    admin_frame :account, {select: select, s: true}
  end
  
  #从--添加--
  post "/admin/account/add" do
    params[:kind] = 0
    select = User.create(params)
    select.save
    admin_frame :account, {select: select, c: true}
  end
  
  #增加用户 界面
  get "/admin/account/add" do
    admin_frame :account, {select: User.new, create: true}
  end
  
  #删除用户
  get "/admin/account/delete" do
    User.find(params[:id]).delete
    select = User.where(kind: 0).first
    admin_frame :account, {select: select}
  end
  
  get "/admin/discuss" do
    user = if params[:id]
      User.find(params[:id])
    else
      User.where(kind: 0).first
    end
    admin_frame :discuss, {user: user}
  end
  
  get "/logout" do
    session[:user] = nil
    redirect to("/login")
  end
  
  helpers do
    def find_order_count meal, id
      if meal
        order = meal.order.find{|item|puts "itemId=#{item["id"]},id=#{id}";item["id"].to_s == id.to_s}
        puts "find order=#{order}"
       if order
         order["count"]
       else
         0
       end
      else
        0
      end
    end
    #评价得分，1-0分，2-60分，3-100分
    def score value
      case value
      when 1
        0
      when 2
        6
      when 3
        10
      end
    end
    #下次点餐的时间描述，如明天，下周一
    def next_work_day_name
      case Time.now.wday
      when 1..4
        "明天"
      when 0, 5, 6
        "下周一"
      end
    end
  end
  
end

Rack::Handler::WEBrick.run App, Port: 3030
