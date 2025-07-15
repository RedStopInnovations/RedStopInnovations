base_url = ENV['BASE_URL']

countries = {
  'au': 'en-au',
  'us': 'en-us',
  'nz': 'en-nz',
  'uk': 'en-gb'
}

important_pages = [
  '',
  '/team',
  '/mobile-podiatry',
  '/mobile-occupational-therapy',
  '/referrals',
  '/about',
  '/mobile-clinic-software'
]

xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.tag! 'urlset', xmlns: 'https://www.sitemaps.org/schemas/sitemap/0.9',
                   'xmlns:xhtml': 'http://www.w3.org/1999/xhtml' do

  countries.each do |country, lang|
    important_pages.each do |link|
      xml.url {
        xml.loc(base_url + '/' + country.to_s + link)
        xml.changefreq("weekly")
        xml.priority 0.8
        countries.each do |sub_country, sub_lang|
          xml.xhtml :link, rel: "alternate", hreflang: sub_lang, href: base_url + "/" + sub_country.to_s + link
        end
      }
    end

    xml.url {
      if country.to_s != 'us'
        xml.loc(base_url + '/' + country.to_s + '/mobile-physiotherapy')
      else
        xml.loc(base_url + '/' + country.to_s + '/mobile-physical-therapy')
      end
      xml.changefreq("weekly")
      xml.priority 0.8
      countries.each do |sub_country, sub_lang|
        if sub_country.to_s != 'us'
          xml.xhtml :link, rel: "alternate", hreflang: sub_lang, href: base_url + "/" + sub_country.to_s + '/mobile-physiotherapy'
        else
          xml.xhtml :link, rel: "alternate", hreflang: sub_lang, href: base_url + "/" + sub_country.to_s + '/mobile-physical-therapy'
        end
      end
    }
  end

  # Posts
  countries.each do |country, lang|
    @posts.each do |post|
      xml.url {
        xml.loc("#{ base_url }#{ frontend_blog_post_path(slug: post.slug, country: country) }")
        xml.changefreq("weekly")
        xml.lastmod post.updated_at.strftime "%Y-%m-%dT%H:%M:%S%:z"
        countries.each do |sub_country, sub_lang|
          xml.xhtml :link, rel: "alternate", hreflang: sub_lang, href: base_url + frontend_blog_post_path(slug: post.slug, country: sub_country.to_s)
        end
      }
    end
  end

  # Team profiles
  @practitioners.each do |pract|
    country = pract.country.try(:downcase)
    if country = 'gb'
      country = 'uk'
    end
    xml.url {
      xml.loc("#{ base_url }#{ frontend_team_profile_path(slug: pract.slug, country: country) }")
      xml.changefreq("weekly")
    }
  end

  # Australian only pages
  pages = [
    '/au/ndis-physiotherapy-brisbane',
    '/au/sunday-physiotherapy',
    '/au/bulk-billed-physiotherapy-brisbane',
    '/au/south-brisbane-mobile-physiotherapy',
    '/au/north-brisbane-mobile-physiotherapy',
    '/au/mobile-physiotherapy',
    '/au/mobile-physiotherapy-brisbane',
    '/au/mobile-physiotherapy-canberra',
    '/au/mobile-physiotherapy-sydney',
    '/au/mobile-physiotherapy-tasmania',
    '/au/mobile-physiotherapy-melbourne',
    '/au/mobile-physiotherapy-adelaide',
    '/au/mobile-physiotherapy-perth',
    '/au/mobile-podiatry',
    '/au/mobile-podiatry-brisbane',
    '/au/mobile-podiatry-sydney',
    '/au/mobile-podiatry-melbourne',
    '/au/mobile-podiatry-adelaide',
    '/au/mobile-podiatry-perth'
  ]

  pages += [
    '/tos',
  ]

  pages.each do |path|
    xml.url {
      xml.loc("#{ base_url }#{ path }")
    }
  end
end
