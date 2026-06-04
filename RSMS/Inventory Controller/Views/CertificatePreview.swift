//
//  CertificatePreview.swift
//  RSMS
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Real QR Code Generator

struct QRCodeView: View {
    let data: String
    let foregroundColor: Color
    let backgroundColor: Color

    private var qrImage: CGImage? {
        let context = CIContext()
        let filter  = CIFilter.qrCodeGenerator()
        filter.message = Data(data.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        // Scale up from the tiny default (21x21 pt) to ~200x200
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        return context.createCGImage(scaled, from: scaled.extent)
    }

    var body: some View {
        if let cgImage = qrImage {
            Image(cgImage, scale: 1.0, label: Text("QR Code"))
                .interpolation(.none)          // Keep it crisp
                .resizable()
                .scaledToFit()
                .colorMultiply(foregroundColor)
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .foregroundStyle(foregroundColor)
        }
    }
}

// MARK: - Certificate Preview

struct CertificatePreview: View {
    let certificateID: String
    let product: Product
    let serialNumber: String
    let date: Date
    let ownerName: String          // ← The actual customer/buyer

    // Exact colors from the luxury image
    let navyBackground = Color(red: 0.11, green: 0.11, blue: 0.17)
    let textCream      = Color(red: 0.9,  green: 0.9,  blue: 0.92)
    let lineGold       = Color(red: 0.4,  green: 0.45, blue: 0.55)

    // QR payload — encodes cert ID + serial so it's actually scannable
    private var qrPayload: String {
        "RSMS-CERT:\(certificateID)|SN:\(serialNumber)|PRODUCT:\(product.sku)"
    }

    var body: some View {
        ZStack {
            navyBackground

            // Outer Border
            Rectangle()
                .stroke(lineGold.opacity(0.4), lineWidth: 1)
                .padding(24)

            // Inner Border
            Rectangle()
                .stroke(lineGold.opacity(0.15), lineWidth: 1)
                .padding(32)

            // Corner Ornaments
            CornerOrnaments(color: lineGold.opacity(0.6))
                .padding(10)

            VStack(spacing: 0) {
                // Top Header
                VStack(spacing: 6) {
                    Text("CERTIFICATE")
                        .font(.custom("Times New Roman", size: 44))
                        .foregroundStyle(textCream)
                        .tracking(3)

                    HStack(spacing: 16) {
                        Rectangle().frame(width: 40, height: 1).foregroundStyle(lineGold.opacity(0.5))
                        Text("OF AUTHENTICITY")
                            .font(.custom("Times New Roman", size: 26))
                            .foregroundStyle(textCream)
                            .tracking(4)
                        Rectangle().frame(width: 40, height: 1).foregroundStyle(lineGold.opacity(0.5))
                    }
                }
                .padding(.top, 75)

                Spacer()

                // Product Title
                Text("\"\(product.name.uppercased())\"")
                    .font(.custom("Times New Roman", size: 36))
                    .foregroundStyle(textCream)
                    .tracking(2)
                    .padding(.bottom, 20)

                // Subtext paragraph
                Text("This certificate verifies the authenticity of the luxury item detailed below and\naffirms that it is an original design produced by the listed designer.")
                    .font(.footnote.weight(.light))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(textCream.opacity(0.7))
                    .lineSpacing(4)
                    .padding(.horizontal, 60)

                Spacer()

                // 3 Columns: Owner | Material | Designer
                HStack(alignment: .top) {

                    // Owner (now the real customer name)
                    VStack(spacing: 6) {
                        Text("OWNER:")
                            .font(.caption.weight(.regular))
                            .tracking(1)
                            .foregroundStyle(textCream.opacity(0.9))
                        Text(ownerName)
                            .font(.subheadline.weight(.light))
                            .foregroundStyle(textCream.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    // Material (from product data)
                    VStack(spacing: 6) {
                        Text("MATERIAL:")
                            .font(.caption.weight(.regular))
                            .tracking(1)
                            .foregroundStyle(textCream.opacity(0.9))
                        Text(product.material ?? product.category.capitalized)
                            .font(.subheadline.weight(.light))
                            .foregroundStyle(textCream.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    // Designer / Brand (from product data)
                    VStack(spacing: 6) {
                        Text("DESIGNER:")
                            .font(.caption.weight(.regular))
                            .tracking(1)
                            .foregroundStyle(textCream.opacity(0.9))
                        Text(product.brand)
                            .font(.subheadline.weight(.light))
                            .foregroundStyle(textCream.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 40)

                Spacer()

                // Bottom Footer Row
                HStack(alignment: .bottom) {

                    // Left: REAL QR Code + Serial
                    VStack(spacing: 12) {
                        QRCodeView(
                            data: qrPayload,
                            foregroundColor: textCream.opacity(0.9),
                            backgroundColor: navyBackground
                        )
                        .frame(width: 56, height: 56)
                        .background(navyBackground)

                        Text("SN: \(serialNumber)")
                            .font(.caption2.weight(.light))
                            .foregroundStyle(textCream.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)

                    // Center: Signature (uses brand name)
                    VStack(spacing: 8) {
                        Text(product.brand)
                            .font(.custom("Snell Roundhand", size: 32))
                            .foregroundStyle(textCream.opacity(0.9))
                            .offset(y: 10)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        Rectangle().frame(width: 140, height: 1).foregroundStyle(lineGold.opacity(0.5))

                        VStack(spacing: 4) {
                            Text(product.brand)
                            Text("Authorized Representative")
                        }
                        .font(.caption2.weight(.light))
                        .foregroundStyle(textCream.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)

                    // Right: Seal + Date
                    VStack(spacing: 12) {
                        ZStack {
                            Image(systemName: "seal.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(Color(red: 0.75, green: 0.65, blue: 0.35))

                            Circle()
                                .stroke(navyBackground, lineWidth: 2)
                                .frame(width: 44, height: 44)

                            Image(systemName: "star.fill")
                                .font(.footnote)
                                .foregroundStyle(navyBackground)
                                .offset(y: -8)

                            Text("OFFICIAL")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(navyBackground)
                                .offset(y: 6)
                        }

                        Text("Issued: \(date.formatted(.dateTime.year().month().day()))")
                            .font(.caption2.weight(.light))
                            .foregroundStyle(textCream.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 60)
                .padding(.horizontal, 20)
            }
        }
        // Landscape certificate aspect ratio
        .aspectRatio(1.4, contentMode: .fit)
    }
}

// MARK: - Corner Ornaments

struct CornerOrnaments: View {
    let color: Color

    var body: some View {
        VStack {
            HStack {
                cornerPiece.rotationEffect(.degrees(0))
                Spacer()
                cornerPiece.rotationEffect(.degrees(90))
            }
            Spacer()
            HStack {
                cornerPiece.rotationEffect(.degrees(270))
                Spacer()
                cornerPiece.rotationEffect(.degrees(180))
            }
        }
    }

    var cornerPiece: some View {
        Image(systemName: "camera.macro")
            .font(.largeTitle.weight(.ultraLight))
            .foregroundStyle(color)
            .offset(x: -15, y: -15)
            .frame(width: 70, height: 70, alignment: .topLeading)
            .clipped()
    }
}
