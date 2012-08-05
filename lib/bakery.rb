# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'guess_html_encoding'

module Bakery
  class Document

    attr_accessor :options, :html, :source

    DEFAULT_OPTIONS = {
      :remove_empty_nodes => true,
      :min_text_length => 80,
      :min_image_width => 150,
      :min_image_height => 100,
      :ignore_image_format => [],
      :debug => true,
    }.freeze

    REGEXES = {
      :replace_brs => /(<br[^>]*>[ \n\r\t]*){2,}/i,
      :replace_fonts => /<(\/?)font[^>]*>/i,
      :replace_comment => /<!--(.*?)-->/i,
      :replace_whitespace => /[\t  ]+/i,
      :replace_emptyline => /[\r\n\f][\r\n\f ]*/i,
      :impurities => /combx|comment|community|disqus|extra|foot|header|menu|remark|rss|shoutbox|sidebar|sponsor|ad-break|agegate|pagination|pager|popup/i,
      :no_impurities => /post|content|article|body|column|main/i,
    }

    def initialize(doc, options = {})
      @source = doc
      @options = DEFAULT_OPTIONS.merge options
      if RUBY_VERSION =~ /^1\.9\./ && !@options[:encoding]
        @source = GuessHtmlEncoding.encode(@source, @options[:html_headers]) unless @options[:do_not_guess_encoding] # Retrieve from http_header
        @options[:encoding] = @source.encoding.to_s # Ruby 1.9 function.
      end

      make_html
      pre_process
      @content = @html.to_html
      process
      post_process

    end

    def make_html
      @source.gsub!(REGEXES[:replace_whitespace], " ")
      @source.gsub!(REGEXES[:replace_brs], '<\p><p>')
      @source.gsub(REGEXES[:replace_fonts], '<\1span>')
      @source.gsub!(REGEXES[:replace_comment], "")
      @html = Nokogiri::HTML(@source, nil, @options[:encoding])
    end

    def pre_process
      @html.css("head, link, meta, script, style").each { |i| i.remove }
      @html.css("*").each do |elem|
        next  if elem.name.downcase == 'html' or elem.name.downcase == 'body'
        str = "##{elem[:id]}.#{elem[:class]}"
        elem.remove  if str =~ REGEXES[:impurities] && str !~ REGEXES[:no_impurities]
      end

      @html.xpath('//text()').each do |node|
        if node.content=~/\S/
          node.content = node.content.strip
        else
          node.remove
        end
      end

    end

    def process
      @best_candidate = {:score => 0}
      @html.css("*").each do |elem|
        score = get_node_score elem
        if score > @best_candidate[:score]
          @best_candidate[:score] = score
          @best_candidate[:node] = elem
        end
        debug "name:#{elem.name.downcase}##{elem[:id]}.#{elem[:class]} with score: #{score}"
      end
      debug "Best candidate => name:#{@best_candidate[:node].name.downcase}##{@best_candidate[:node][:id]}.#{@best_candidate[:node][:class]} with score: #{@best_candidate[:score]} "


      @best_candidate[:node].css("*").each do |elem|
        # Remove elem when link_density is too high.
        elem.remove  if elem.css("a").count >= 4 and get_link_density(elem) > 0.6
      end

      @node = @best_candidate[:node]
    end

    def post_process

      ([@node] + @node.css("*")).each do |elem|
        # Remove annoying attrs
        elem.attributes.each { |name, value| elem.delete(name) unless @options[:attrs] && @options[:attrs].include?(name.to_s) }
      end

      normalize_image
      alternative_image

      if @options[:remove_empty_nodes]
        # remove <p> tags that have no text content - this will also remove p tags that contain only images.
        @node.css("p, li, ul, ol, b, strong, a").each do |elem|
          # Remove utf-8 blank string.
          elem.remove if elem.css("img").empty? and elem.content.delete(" ").strip.empty?
        end
      end

      return '' if !@node || !@node.to_html || @node.to_html.empty? || @node.text.length < 450

      # Get rid of duplicate whitespace
      @content = @node.to_html
      @content.gsub!(/[\r\n\f]([ ]*)/, "\n").gsub!(/[\r\n\f]+/, "\n" ).gsub!(/[\t   ]+/, " ")
      write  if @options[:debug]
    end

    def content
      @content
    end

    # Make iamge url to absolute path and discard small images
    def normalize_image
      begin
        require 'mini_magick'
        require 'uri'
      rescue LoadError
        raise "Please install mini_magick in order to use the #images feature."
      end

      @node.css('img').each do |el|

        el.remove and next unless el[:src]

        image = load_image(el)
        el.remove and next unless image
        el.remove and next unless image_meets_criteria?(image)
        el[:width] = image[:width].to_s; el[:height] = image[:height].to_s
        el[:class] = "small"  if image[:width] <= 200 && image[:height] <= 500
      end
    end

    def alternative_image
      if @node.css("img").count == 0
        # Get the bigest one from body
        bigest_image = nil
        @html.at_css("body").css("img").each do |el|
          image = load_image(el)
          if image
            el[:width] = image[:width].to_s; el[:height] = image[:height].to_s
            if image[:width] >= 400 and image[:height] >= 400
              if not bigest_image
                bigest_image = el
              else image[:width] > bigest_image[:width].to_i and image[:height] > bigest_image[:height].to_i
                bigest_image = el
              end
            end
          end
        end

        if bigest_image
          # Add into best candidate
          @node << bigest_image
        end
      end
    end

    def load_image(el)
      begin
        if not URI.parse(el[:src]).host # relative path
          el[:src] = URI.parse(@options[:url]).merge(el[:src]).to_s  if @options[:url] # Get absolute path
        end
        MiniMagick::Image.open(el[:src])
      rescue => e
        debug("Image error: #{e}")
        nil
      end
    end

    def image_meets_criteria?(image)
      return false if @options[:ignore_image_format].include?(image[:format].downcase)
      image[:width] >= (@options[:min_image_width] || 0) && image[:height] >= (@options[:min_image_height] || 0)
    end


    def remove_annoying_attrs(elem)
      elem.each do |name, value|
        elem.delete name  unless @options[:attrs] && @options[:attrs].include?(name.to_s)
      end
    end

    def get_plain_text(node_org)
      node = node_org.clone
      node.css("div, li, ul, ol, .nav, td").each do |elem|
        elem.remove  if get_link_density(elem) > 0.7
      end

      5.times do
        node.css("*").each do |elem|
          elem.remove  if elem.text.length < @options[:min_text_length]
        end
      end

      node.text
    end

    def get_node_score(elem)
      get_plain_text(elem).length / Math.sqrt(elem.to_html.length)
    end

    def get_link_density(elem)
      link_length = elem.css("a").map(&:text).join("").length
      text_length = elem.text.length
      link_length / text_length.to_f
    end

    def write
      File.open("./public/bakery_test.html", File::RDWR|File::CREAT|File::TRUNC) do |f|
        f.puts @content
      end
    end

    def debug(info)
      puts info  if @options[:debug]
    end

  end
end
