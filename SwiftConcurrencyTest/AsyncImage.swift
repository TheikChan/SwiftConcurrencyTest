//
//  AsyncImage.swift
//  SwiftConcurrencyTest
//
//  Created by Theik Chan on 11/09/2024.
//

import SwiftUI
import Combine

class DownloadImageLoader {
    
    let url = URL(string: "https://picsum.photos/200")!
    
    func handleResponse(data: Data?, response: URLResponse?) -> UIImage? {
        guard let data = data,
        let image = UIImage(data: data),
        let response = response as? HTTPURLResponse,
              response.statusCode >= 200 && response.statusCode < 300 else {
            return nil
        }
        
        return image
    }
    
    func downloadWithEscaping(completionHandler: @escaping (_ image: UIImage?,_ error: Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            let image = self?.handleResponse(data: data, response: response)
            completionHandler(image,error)
        }
        .resume()
    }
    
    func downloadWithCombine() -> AnyPublisher<UIImage?, Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map(handleResponse)
            .mapError({ $0 })
            .eraseToAnyPublisher()
    }
}

class NetworkAsyncImageViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    
    let loader = DownloadImageLoader()
    var cancellable = Set<AnyCancellable>()
    
    public func fetchImage() {
//        loader.downloadWithEscaping { [weak self] image, error in
//            DispatchQueue.main.async {
//                self?.image = image
//            }
//        }
        loader.downloadWithCombine()
            .receive(on: DispatchQueue.main)
            .sink { _ in
            } receiveValue: { [weak self] image in
                self?.image = image
            }.store(in: &cancellable)
    }
}

struct NetworkAsyncImage: View {
    
    @StateObject private var viewModel = NetworkAsyncImageViewModel()
    
    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
            }
        }.onAppear {
            viewModel.fetchImage()
        }
    }
    
}

#Preview {
    NetworkAsyncImage()
}
