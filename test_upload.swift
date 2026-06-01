import Foundation

let url = URL(string: "https://lidoouszbcutddwrxbgy.supabase.co/storage/v1/object/lookbooks/test.txt")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("sb_publishable_X11_v94UKdMch6EBFq1eyA_9jGIJuD8", forHTTPHeaderField: "apikey")
request.setValue("Bearer sb_publishable_X11_v94UKdMch6EBFq1eyA_9jGIJuD8", forHTTPHeaderField: "Authorization")
request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

let data = "hello world".data(using: .utf8)!

let semaphore = DispatchSemaphore(value: 0)

let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
    if let error = error {
        print("Error: \(error.localizedDescription)")
    }
    if let httpResponse = response as? HTTPURLResponse {
        print("Status: \(httpResponse.statusCode)")
    }
    if let data = data, let str = String(data: data, encoding: .utf8) {
        print("Body: \(str)")
    }
    semaphore.signal()
}
task.resume()

semaphore.wait()
