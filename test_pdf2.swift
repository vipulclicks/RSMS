import Foundation
import PDFKit

let url = URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")!
let doc = PDFDocument(url: url)
print("Doc is nil? \(doc == nil)")
