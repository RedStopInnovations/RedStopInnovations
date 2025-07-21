base_url = ENV['BASE_URL']

important_pages = [
  '',
  '/team',
  '/referrals',
  '/about',
]

xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.tag! 'urlset', xmlns: 'https://www.sitemaps.org/schemas/sitemap/0.9',
                   'xmlns:xhtml': 'http://www.w3.org/1999/xhtml' do

  important_pages.each do |link|
    xml.url {
      xml.loc(base_url + '/' + link)
      xml.changefreq("weekly")
      xml.priority 0.8
      xml.xhtml :link, rel: "alternate", hreflang: 'en-au', href: base_url + "/" + link
    }
  end


  # Practitioner profiles
  @practitioners.each do |pract|
    xml.url {
      xml.loc("#{ base_url }#{ frontend_team_profile_path(slug: pract.slug) }")
      xml.changefreq("weekly")
    }
  end

  pages += [
    '/tos',
  ]

  pages.each do |path|
    xml.url {
      xml.loc("#{ base_url }#{ path }")
    }
  end
end
