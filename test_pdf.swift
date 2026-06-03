import Foundation
import PDFKit

let url = URL(string: "https://lidoouszbcutddwrxbgy.supabase.co/storage/v1/object/public/lookbooks/test.pdf")!
let doc = PDFDocument(url: url)
print(doc != nil)
