#encoding: utf-8
module AddOn
  
  #登录，如果成功返回user，失败返回nil
  def login cardId, pwd
    user = User.where(cardId: cardId).first
    puts "login user=#{user}"
    #用户存在
    if user
      if user.pwd == pwd
        request[:m] = "s"
        session[:user] = user
        cookies[:cardId] = cardId
        cookies[:pwd] = pwd
        user
      else
        request[:m] = "账号密码错误"
        nil
      end
    else
      request[:m] = "账号不存在"
      nil
    end
  end
  
  def frame name, p={}
    par = Hash.new
    par[:inner] = p
    par[:innerView] = name
    erb :frame, locals: par
  end
  
  def admin_frame name, p={}
    par = Hash.new
    par[:inner] = p
    par[:innerView] = :"admin/#{name}"
    erb :"admin/frame", locals: par
  end
  
  def random_img_name suffix
    time = Time.now.to_i
    name = "/image/#{time}_#{Random.rand(time)}#{suffix}"
    puts "random_img_name=#{name}"
    name
  end
  
end