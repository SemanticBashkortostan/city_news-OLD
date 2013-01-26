I18n.locale = :ru # or whatever your default locale is
I18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml")]
I18n.reload!