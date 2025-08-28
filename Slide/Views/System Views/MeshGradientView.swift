import SwiftUI

// MARK: - Original Version
struct MeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.1 : 0.8, 0.5],
                [1.0, isAnimating ? 0.5 : 1],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .purple.opacity(0.0), .indigo.opacity(0.0),
                .purple.opacity(0.0),
                isAnimating ? .mint.opacity(0.3) : .purple.opacity(0.3),
                .blue.opacity(0.3), .blue.opacity(0.3),
                .purple.opacity(0.6), .indigo.opacity(0.6),
                .purple.opacity(0.6),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.0).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Sunset Style
struct SunsetMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.2 : 0.7, 0.5],
                [1.0, isAnimating ? 0.3 : 0.8],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .orange.opacity(0.8), .yellow.opacity(0.6),
                .orange.opacity(0.8),
                isAnimating ? .red.opacity(0.7) : .orange.opacity(0.5),
                .pink.opacity(0.6), .red.opacity(0.7),
                .purple.opacity(0.9), .indigo.opacity(0.8),
                .purple.opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 4.0).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Ocean Style
struct OceanMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.3 : 0.6, 0.5],
                [1.0, isAnimating ? 0.7 : 0.4],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .cyan.opacity(0.4), .blue.opacity(0.3), .teal.opacity(0.4),
                isAnimating ? .teal.opacity(0.6) : .cyan.opacity(0.5),
                .blue.opacity(0.7), .indigo.opacity(0.6),
                .blue.opacity(0.9), .blue.opacity(0.8), .blue.opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 5.0).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Forest Style
struct ForestMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.4 : 0.9, 0.5],
                [1.0, isAnimating ? 0.2 : 0.6],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .mint.opacity(0.3), .green.opacity(0.4), .mint.opacity(0.3),
                isAnimating ? .green.opacity(0.6) : .mint.opacity(0.5),
                .green.opacity(0.7), .teal.opacity(0.6),
                .green.opacity(0.9), .brown.opacity(0.7), .green.opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 6.0).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Monochrome Style
struct MonochromeMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.6 : 0.4, 0.5],
                [1.0, isAnimating ? 0.4 : 0.6],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .gray.opacity(0.2), .white.opacity(0.3), .gray.opacity(0.2),
                isAnimating ? .black.opacity(0.4) : .gray.opacity(0.5),
                .gray.opacity(0.6), .white.opacity(0.4),
                .black.opacity(0.8), .gray.opacity(0.7), .black.opacity(0.8),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.5).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Neon Style
struct NeonMeshGradientView: View {
    @State var isAnimating = false
    var duration: Double = 1.5

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.1 : 0.9, 0.5],
                [1.0, isAnimating ? 0.9 : 0.1],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .pink.opacity(0.7), .purple.opacity(0.8), .pink.opacity(0.7),
                isAnimating ? .cyan.opacity(0.9) : .pink.opacity(0.8),
                .purple.opacity(0.9), .cyan.opacity(0.8),
                .black.opacity(0.9), .purple.opacity(0.9), .black.opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Aurora Style
struct AuroraMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.2 : 0.8, 0.5],
                [1.0, isAnimating ? 0.6 : 0.3],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .green.opacity(0.5), .teal.opacity(0.4), .green.opacity(0.5),
                isAnimating ? .purple.opacity(0.7) : .green.opacity(0.6),
                .teal.opacity(0.8), .purple.opacity(0.7),
                .black.opacity(0.9), .indigo.opacity(0.8), .black.opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 7.0).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Fire Style
struct FireMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.3 : 0.7, 0.5],
                [1.0, isAnimating ? 0.8 : 0.2],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .yellow.opacity(0.6), .orange.opacity(0.7),
                .yellow.opacity(0.6),
                isAnimating ? .red.opacity(0.8) : .orange.opacity(0.7),
                .red.opacity(0.9), .orange.opacity(0.8),
                .red.opacity(0.9), .black.opacity(0.8), .red.opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Pastel Style
struct PastelMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.5 : 0.5, 0.5],
                [1.0, isAnimating ? 0.4 : 0.6],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .pink.opacity(0.3), .purple.opacity(0.2), .pink.opacity(0.3),
                isAnimating ? .mint.opacity(0.4) : .pink.opacity(0.3),
                .purple.opacity(0.3), .mint.opacity(0.3),
                .blue.opacity(0.4), .purple.opacity(0.4), .blue.opacity(0.4),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8.0).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Custom Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (
                255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17
            )
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (
                int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF
            )
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Cyberpunk Style
struct CyberpunkMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.1 : 0.9, 0.5],
                [1.0, isAnimating ? 0.8 : 0.2],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                Color(hex: "FF0080").opacity(0.6),
                Color(hex: "00FFFF").opacity(0.5),
                Color(hex: "FF0080").opacity(0.6),
                isAnimating
                    ? Color(hex: "00FFFF").opacity(0.8)
                    : Color(hex: "FF0080").opacity(0.7),
                Color(hex: "8A2BE2").opacity(0.7),
                Color(hex: "00FFFF").opacity(0.8),
                Color(hex: "000000").opacity(0.9),
                Color(hex: "4B0082").opacity(0.8),
                Color(hex: "000000").opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Vaporwave Style
struct VaporwaveMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.3 : 0.7, 0.5],
                [1.0, isAnimating ? 0.6 : 0.4],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                Color(hex: "FF6B9D").opacity(0.7),
                Color(hex: "A8E6CF").opacity(0.6),
                Color(hex: "FF6B9D").opacity(0.7),
                isAnimating
                    ? Color(hex: "FFD93D").opacity(0.8)
                    : Color(hex: "FF6B9D").opacity(0.6),
                Color(hex: "6BCF7F").opacity(0.7),
                Color(hex: "4D96FF").opacity(0.8),
                Color(hex: "9B59B6").opacity(0.9),
                Color(hex: "3F51B5").opacity(0.8),
                Color(hex: "9B59B6").opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 4.5).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Autumn Style
struct AutumnMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.4 : 0.6, 0.5],
                [1.0, isAnimating ? 0.7 : 0.3],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                Color(hex: "D2691E").opacity(0.6),
                Color(hex: "FF8C00").opacity(0.7),
                Color(hex: "CD853F").opacity(0.6),
                isAnimating
                    ? Color(hex: "B22222").opacity(0.8)
                    : Color(hex: "D2691E").opacity(0.7),
                Color(hex: "FF4500").opacity(0.8),
                Color(hex: "8B4513").opacity(0.7),
                Color(hex: "8B4513").opacity(0.9),
                Color(hex: "A0522D").opacity(0.8),
                Color(hex: "654321").opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 5.5).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Galaxy Style
struct GalaxyMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.2 : 0.8, 0.5],
                [1.0, isAnimating ? 0.9 : 0.1],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                Color(hex: "2C1810").opacity(0.8),
                Color(hex: "191970").opacity(0.7),
                Color(hex: "2C1810").opacity(0.8),
                isAnimating
                    ? Color(hex: "9932CC").opacity(0.9)
                    : Color(hex: "4B0082").opacity(0.8),
                Color(hex: "8A2BE2").opacity(0.8),
                Color(hex: "FF1493").opacity(0.7),
                Color(hex: "000000").opacity(1.0),
                Color(hex: "191970").opacity(0.9),
                Color(hex: "000000").opacity(1.0),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 6.0).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Mint Fresh Style
struct MintFreshMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.5 : 0.5, 0.5],
                [1.0, isAnimating ? 0.3 : 0.7],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                Color(hex: "E8F5E8").opacity(0.7),
                Color(hex: "B8E6B8").opacity(0.6),
                Color(hex: "E8F5E8").opacity(0.7),
                isAnimating
                    ? Color(hex: "00CED1").opacity(0.8)
                    : Color(hex: "90EE90").opacity(0.7),
                Color(hex: "20B2AA").opacity(0.8),
                Color(hex: "48D1CC").opacity(0.7),
                Color(hex: "008B8B").opacity(0.9),
                Color(hex: "2F4F4F").opacity(0.8),
                Color(hex: "008B8B").opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.5).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Coral Reef Style
struct CoralReefMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.6 : 0.4, 0.5],
                [1.0, isAnimating ? 0.2 : 0.8],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                Color(hex: "FF7F7F").opacity(0.6),
                Color(hex: "FFA07A").opacity(0.7),
                Color(hex: "FF6347").opacity(0.6),
                isAnimating
                    ? Color(hex: "FF4500").opacity(0.8)
                    : Color(hex: "FF7F7F").opacity(0.7),
                Color(hex: "FF69B4").opacity(0.8),
                Color(hex: "FF1493").opacity(0.7),
                Color(hex: "008B8B").opacity(0.9),
                Color(hex: "20B2AA").opacity(0.8),
                Color(hex: "4682B4").opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 4.0).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Twilight Style
struct TwilightMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.3 : 0.7, 0.5],
                [1.0, isAnimating ? 0.8 : 0.2],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                Color(hex: "F0E68C").opacity(0.5),
                Color(hex: "DDA0DD").opacity(0.6),
                Color(hex: "F0E68C").opacity(0.5),
                isAnimating
                    ? Color(hex: "9370DB").opacity(0.8)
                    : Color(hex: "DDA0DD").opacity(0.7),
                Color(hex: "8A2BE2").opacity(0.8),
                Color(hex: "4B0082").opacity(0.7),
                Color(hex: "191970").opacity(0.9),
                Color(hex: "2F4F4F").opacity(0.8),
                Color(hex: "191970").opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 7.0).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Electric Blue Style
struct ElectricBlueMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.1 : 0.9, 0.5],
                [1.0, isAnimating ? 0.7 : 0.3],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                Color(hex: "7DF9FF").opacity(0.6),
                Color(hex: "00BFFF").opacity(0.7),
                Color(hex: "1E90FF").opacity(0.6),
                isAnimating
                    ? Color(hex: "0080FF").opacity(0.9)
                    : Color(hex: "4169E1").opacity(0.8),
                Color(hex: "0000FF").opacity(0.8),
                Color(hex: "8A2BE2").opacity(0.7),
                Color(hex: "000080").opacity(0.9),
                Color(hex: "191970").opacity(0.8),
                Color(hex: "000000").opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Rose Gold Style
struct RoseGoldMeshGradientView: View {
    @State var isAnimating = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.4 : 0.6, 0.5],
                [1.0, isAnimating ? 0.6 : 0.4],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                Color(hex: "FFE4E1").opacity(0.7),
                Color(hex: "F0C0C0").opacity(0.6),
                Color(hex: "FFE4E1").opacity(0.7),
                isAnimating
                    ? Color(hex: "CD919E").opacity(0.8)
                    : Color(hex: "F0C0C0").opacity(0.7),
                Color(hex: "B76E79").opacity(0.8),
                Color(hex: "CD919E").opacity(0.7),
                Color(hex: "8B4A6B").opacity(0.9),
                Color(hex: "704A5C").opacity(0.8),
                Color(hex: "8B4A6B").opacity(0.9),
            ]
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 6.5).repeatForever(autoreverses: true)
            ) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Usage Example
struct GradientsView: View {
    @State private var selectedStyle = 0

    let gradientViews: [AnyView] = [
        AnyView(MeshGradientView()),
        AnyView(SunsetMeshGradientView()),
        AnyView(OceanMeshGradientView()),
        AnyView(ForestMeshGradientView()),
        AnyView(MonochromeMeshGradientView()),
        AnyView(NeonMeshGradientView()),
        AnyView(AuroraMeshGradientView()),
        AnyView(FireMeshGradientView()),
        AnyView(PastelMeshGradientView()),
        AnyView(CyberpunkMeshGradientView()),
        AnyView(VaporwaveMeshGradientView()),
        AnyView(AutumnMeshGradientView()),
        AnyView(GalaxyMeshGradientView()),
        AnyView(MintFreshMeshGradientView()),
        AnyView(CoralReefMeshGradientView()),
        AnyView(TwilightMeshGradientView()),
        AnyView(ElectricBlueMeshGradientView()),
        AnyView(RoseGoldMeshGradientView()),
    ]

    let styleNames = [
        "Original", "Sunset", "Ocean", "Forest", "Monochrome",
        "Neon", "Aurora", "Fire", "Pastel", "Cyberpunk",
        "Vaporwave", "Autumn", "Galaxy", "Mint Fresh", "Coral Reef",
        "Twilight", "Electric Blue", "Rose Gold",
    ]

    var body: some View {
        ZStack {
            gradientViews[selectedStyle]

            VStack {
                Spacer()
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(0..<styleNames.count, id: \.self) { index in
                            Button(styleNames[index]) {
                                selectedStyle = index
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .font(.caption)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    GradientsView()
}