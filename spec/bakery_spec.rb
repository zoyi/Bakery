# -*- coding: utf-8 -*-
# Bakery algorithm
require 'bakery'
def bakery_with_file(file_name, url)
#  pwd = "/home/#{ENV['USER']}/exp/cooki/oven/spec/libs/bakery/"
  # bakery = Bakery::Document.new(File.read(File.join(File.dirname(__FILE__), file_name)),
  #                                         :tags => %w[div p img a br ol li ul],
  #                                         :attributes => %w[src href],
  #                                         )
  bakery = Bakery::Document.new(File.read(File.join(File.dirname(__FILE__), file_name)),
                                :attrs => %w[src href],
                                :url => url,
                                )
end

describe Bakery do

  describe Bakery::Document do

    it "Case http://www.wired.co.uk/news/archive/2012-07/30/jonathan-ive-saying-no" do
      bakery = bakery_with_file "www.wired.co.uk.html", "http://www.wired.co.uk/news/archive/2012-07/30/jonathan-ive-saying-no"
      bakery.content.should include("Apple has been preparing for mass production on a number of")
      bakery.content.should include("The company also has to hold products back even when they think")
    end


    it "Case http://techcrunch.com/2012/07/31/were-having-a-party-and-there-will-be-a-tiger-a-monkey-and-snoop-lion-not-really/" do
      bakery = bakery_with_file "www.techcrunch.com.html", "http://techcrunch.com/2012/07/31/were-having-a-party-and-there-will-be-a-tiger-a-monkey-and-snoop-lion-not-really/"
      bakery.content.should include("Guys, guys, so because everybody obviously wants to")
      bakery.content.should include("Here comes the hard")
    end

    it "Case http://www.goal.com/kr/news/1794/%ED%95%B4%EC%99%B8%ED%8C%8C/2012/08/01/3278894/%EB%B0%95%EC%A3%BC%EC%98%81-%EC%95%84%EC%8A%A4%EB%82%A0-%ED%83%88%EC%B6%9C%EB%B8%94%EB%9E%99%EB%B2%88-%EB%9F%AC%EB%B8%8C%EC%BD%9C" do
      bakery = bakery_with_file "www.goal.com.html", "http://www.goal.com/kr/news/1794/%ED%95%B4%EC%99%B8%ED%8C%8C/2012/08/01/3278894/%EB%B0%95%EC%A3%BC%EC%98%81-%EC%95%84%EC%8A%A4%EB%82%A0-%ED%83%88%EC%B6%9C%EB%B8%94%EB%9E%99%EB%B2%88-%EB%9F%AC%EB%B8%8C%EC%BD%9C"
      bakery.content.should include("박주영은 지난여름 큰 기대를 받으며 아스날에 입단했지만")
      bakery.content.should include("여기에 아르센 벵거 감독은 최근 인터뷰에서")
    end

    it "Case http://breaknews.com/sub_read.html?uid=223140&section=sc4" do
      bakery = bakery_with_file "www.breaknews.com.html", "http://breaknews.com/sub_read.html?uid=223140&section=sc4"
      bakery.content.should include("올림픽 메달 순위에서 한국이 종합 3위를 기록 중이다.")
      bakery.content.should include("한국은 사격 진종오, 여자 양궁대표팀, 유도 김재범에 이어")
    end

    it "Case http://realtime.wsj.com/korea/2012/08/01/%EC%B0%BD%EC%97%85%ED%95%98%EA%B8%B0-%EC%A0%84%EC%97%90-%EA%B3%A0%EB%A0%A4%ED%95%A0-5%EA%B0%80%EC%A7%80/" do
      bakery = bakery_with_file "realtime.wsj.com.html", "http://realtime.wsj.com/korea/2012/08/01/%EC%B0%BD%EC%97%85%ED%95%98%EA%B8%B0-%EC%A0%84%EC%97%90-%EA%B3%A0%EB%A0%A4%ED%95%A0-5%EA%B0%80%EC%A7%80/"
      bakery.content.should include("창업은 양육과 여러 면에서 비슷하다.")
      bakery.content.should include("창업 후 초기가 힘든 것은 사실이다.")
    end

    it "Case: Mashable (http://mashable.com/2012/07/31/outlook-hotmail-review/)" do
      bakery = bakery_with_file "case_mashable.html", "http://mashable.com/2012/07/31/outlook-hotmail-review/"
      bakery.content.should include("<h2>Email Ads, the Microsoft Way</h2>")
      bakery.content.should_not include('This is the new Hotmail, which is now officially called Outlook (it had the label "NewMail" in the preview).')
    end

    it "Case: Economist (http://www.economist.com/node/21559624)" do
      bakery = bakery_with_file "case_www.economist.com_8_3.html", "http://www.economist.com/node/21559624"
      bakery.content.should include("<p>Apple has arguably helped to modernise Chinese attitudes towards enterprise and design.")
      bakery.content.should_not include('Canucks, meet CNOOC</a>')
    end

  end

end
