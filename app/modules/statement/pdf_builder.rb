module Statement
  module PdfBuilder
    def self.build(account_statement, options = {})
      template =
        case account_statement.source
        when Patient
          'pdfs/patient_account_statement'
        when Contact
          if account_statement.options['type'] == 'Super'
            'pdfs/statements/contact_super_account_statement'
          else
            'pdfs/contact_account_statement'
          end
        else
          raise "Unknown #{account_statement.source_type} source type for account statement"
        end

      html_renderer = ActionController::Base.new
      pdf_html = html_renderer.render_to_string(
        template: template,
        layout: nil,
        locals: {
          account_statement: account_statement,
          options: options
        }
      )

      WickedPdf.new.pdf_from_string(pdf_html)
    end
  end
end
