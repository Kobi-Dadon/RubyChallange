require 'nokogiri'
require 'open-uri'
require 'uri'
require 'net/http'

class MembersController < ApplicationController

  def index
    @member = Member.all
  end

  def show
    @member = Member.find(params[:id])
  end

  def new
    @member = Member.new
  end

  def create
    @member = Member.new(member_params)

    #get all the headers from the website
    document = Nokogiri::HTML(open(@member.website))
    headers = document.css('h1').text + document.css('h2').text + document.css('h3').text
    @member.headers = headers

    #goo.gl API is no longer available and bitly require OAuth so i did this little trick with shorturl
    params = {'u' => @member.website}
    document = Net::HTTP.post_form(URI.parse('https://www.shorturl.at/url-shortener.php'), params)
    website_body = Nokogiri::HTML(document.body)
    @member.short_web = website_body.css('#shortenurl')[0]['value']

    if @member.save
      redirect_to @member
    else
      render 'new'
    end

  end

  def edit
    #create the friendshio in 2 directions within the relations table
    Friendship.create(member_id: params['member_id'], friend_id: params['friend_id'])
    Friendship.create(member_id: params['friend_id'], friend_id: params['member_id'])
    redirect_back(fallback_location: root_path)
  end

  def member_not_friends(mmbr_id)
    # get all the members that are not yet friends with the member
    Member.where.not(id: Friendship.where(member_id: mmbr_id).pluck(:friend_id)).where.not(id: mmbr_id)
  end
  helper_method :member_not_friends

  def member_friends(mmbr_id)
    #get all member friends
    Member.where(id: Friendship.where(member_id: mmbr_id).pluck(:friend_id)).where.not(id: mmbr_id)
  end
  helper_method :member_friends

  def num_of_friends(mmbr_id)
    # get number of friends for member
    Friendship.where(member_id: mmbr_id).size.to_s
  end
  helper_method :num_of_friends

  def find_path(friends_lst, mmbr_id, topic, path_array = [])
    #find the path between a member and another member (not within first friends cycle) that have the topic wanted in headers
    frnds_dtls = Member.where(:id => friends_lst).where.not(:id => path_array)
    frnds_dtls.each do |f|
      if f.headers.downcase.include? topic.downcase and Friendship.where(member_id: mmbr_id).where(friend_id: f.id).size <= 0
        path_array.push(f.id)
        path_array.unshift('x')
        #if match found, return the chain with 'x' identifier as success
        return path_array
      else
        nxt_friends = Friendship.select(:friend_id).distinct.where(member_id: f.id).where.not(friend_id: mmbr_id).where.not(:member_id => path_array).pluck(:friend_id)
        if nxt_friends.any?
          path_array.push(f.id)
          find_path(nxt_friends, mmbr_id, topic, path_array)
        end
      end
    end
    if path_array[0] == 'x'
      return path_array
    end
    return nil
  end

  def find_topic
    # a method to call in order to find path to friend with a specific topic

    #get member friends and start looking from their friends
    member_friends = Friendship.select(:friend_id).distinct.where(member_id: params['id']).pluck(:friend_id)
    result = find_path(member_friends, params['id'], params['topic'])
    if !result.nil? and result.length > 0 and result[0] == 'x'
      result.shift
      path = Member.where(:id => result).pluck(:name).map(&:inspect).join('->')
      @path = path + ' ('+params['topic']+')'
    else
      @path = 'No results found for that keyword, please try a different one.'
    end
    session[:path] = @path
    redirect_back fallback_location: { action: "show", id: params['id'], path: @path }
  end

  private
    def member_params
      params.require(:members).permit(:name, :website)
    end

end
