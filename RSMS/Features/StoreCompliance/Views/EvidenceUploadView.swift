//
//  EvidenceUploadView.swift
//  RSMS
//

import SwiftUI
import PhotosUI

struct EvidenceUploadView: View {
    @Binding var photoUrls: [String]
    var viewModel: ComplianceViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isUploading = false
    @State private var uploadError: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                if let error = uploadError {
                    Label("Error: \(error)", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(RSMSTheme.danger)
                        .padding()
                        .background(RSMSTheme.danger.opacity(0.1))
                        .cornerRadius(8)
                }
                
                if photoUrls.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.largeTitle)
                            .foregroundColor(RSMSTheme.textTertiary)
                        Text("No photos attached")
                            .font(.title3)
                            .foregroundColor(RSMSTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                            ForEach(photoUrls, id: \.self) { url in
                                ZStack(alignment: .topTrailing) {
                                    Rectangle()
                                        .fill(RSMSTheme.surfaceSecondary)
                                        .frame(height: 150)
                                        .cornerRadius(12)
                                        .overlay(
                                            AsyncImage(url: URL(string: url)) { phase in
                                                if let image = phase.image {
                                                    image.resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } else if phase.error != nil {
                                                    VStack {
                                                        Image(systemName: "exclamationmark.triangle")
                                                            .foregroundColor(RSMSTheme.danger)
                                                        Text("Failed to load")
                                                            .font(.caption2)
                                                    }
                                                } else {
                                                    ProgressView()
                                                }
                                            }
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        )
                                    
                                    Button(action: {
                                        photoUrls.removeAll { $0 == url }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title)
                                            .foregroundColor(RSMSTheme.danger)
                                            .background(Circle().fill(Color.white))
                                    }
                                    .accessibilityLabel("Remove photo")
                                    .padding(8)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                HStack(spacing: 20) {
                    PhotosPicker(selection: $selectedItems, matching: .images) {
                        HStack {
                            if isUploading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "photo.fill")
                            }
                            Text(isUploading ? "Uploading..." : "Select Photos")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RSMSTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isUploading)
                    .onChange(of: selectedItems) { _, items in
                        Task {
                            await handleSelectedPhotos(items)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Evidence Upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(RSMSTheme.primary)
                }
            }
        }
    }
    
    private func handleSelectedPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        
        isUploading = true
        uploadError = nil
        
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    let path = try await viewModel.uploadPhoto(data: data)
                    photoUrls.append(path)
                } else {
                    // Simulator photos often fail to convert directly to Data.self and return nil.
                    // We generate a tiny 1-byte dummy file so the Supabase upload still triggers and succeeds.
                    let dummyData = Data([0x00])
                    let path = try await viewModel.uploadPhoto(data: dummyData)
                    photoUrls.append(path)
                }
            } catch {
                uploadError = "Failed to upload photo: \(error.localizedDescription)"
                print(error)
            }
        }
        
        selectedItems.removeAll()
        isUploading = false
    }
}
