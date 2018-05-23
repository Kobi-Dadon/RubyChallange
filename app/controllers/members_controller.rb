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

    # this section should have been in another place but it's here due to timing limitation.

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

  private
    def member_params
      params.require(:members).permit(:name, :website)
    end

end
