import SwiftUI
import PhotosUI
#if os(iOS)
import UIKit
#endif

struct AvatarEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userProfile: UserProfile
    @State private var selectedTab = 0
    @State private var showingImagePicker = false
    #if os(iOS)
    @State private var selectedImage: UIImage?
    #endif
    
    private var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    // Avatar creator states
    @State private var selectedGender = 0 // 0: male, 1: female
    @State private var selectedSkinTone = 2
    @State private var selectedFaceShape = 0
    @State private var selectedHairStyle = 0
    @State private var selectedHairColor = 0
    @State private var selectedEyeShape = 0
    @State private var selectedEyeColor = 0
    @State private var selectedEyebrows = 0
    @State private var selectedNose = 0
    @State private var selectedMouth = 0
    @State private var selectedFacialHair = 0
    @State private var selectedOutfit = 0
    @State private var selectedAccessory = 0
    @State private var selectedGlasses = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Avatar preview
                avatarPreview
                
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    photoUploadTab
                        .tag(0)
                    
                    avatarCreatorTab
                        .tag(1)
                }
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                #endif
                
                Spacer()
                
                // Save button
                saveButton
            }
            .background(systemGroupedBackground)
            .navigationTitle(LocalizationManager.shared.localizedString("Edit Avatar"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationManager.shared.localizedString("Cancel")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationManager.shared.localizedString("Cancel")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
                #endif
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        #endif
    }
    
    private var avatarPreview: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 140, height: 140)
                
                #if os(iOS)
                if selectedTab == 0, let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                } else if selectedTab == 1 {
                    // Custom avatar preview
                    customAvatarView
                        .frame(width: 130, height: 130)
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                }
                #else
                if selectedTab == 1 {
                    // Custom avatar preview
                    customAvatarView
                        .frame(width: 130, height: 130)
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                }
                #endif
            }
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            Text(selectedTab == 0 ? LocalizationManager.shared.localizedString("Upload Photo") : LocalizationManager.shared.localizedString("Create Avatar"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.top, 20)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            Button(action: { selectedTab = 0 }) {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                    Text(LocalizationManager.shared.localizedString("Photo"))
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(selectedTab == 0 ? .blue : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selectedTab == 0 ? Color.blue.opacity(0.1) : Color.clear)
            }
            
            Button(action: { selectedTab = 1 }) {
                VStack(spacing: 8) {
                    Image(systemName: "paintbrush")
                        .font(.system(size: 20))
                    Text(LocalizationManager.shared.localizedString("Create"))
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(selectedTab == 1 ? .blue : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selectedTab == 1 ? Color.blue.opacity(0.1) : Color.clear)
            }
        }
        .background(secondarySystemGroupedBackground)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var photoUploadTab: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text(LocalizationManager.shared.localizedString("Upload your photo from gallery or take a new one"))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 40)
            
            #if os(iOS)
            Button(action: { showingImagePicker = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                    Text(LocalizationManager.shared.localizedString("Select photo"))
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
            #else
            Button(action: { }) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                    Text(LocalizationManager.shared.localizedString("Select photo"))
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            #endif
            
            Spacer()
        }
    }
    
    private var avatarCreatorTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Лицо
                sectionHeader(LocalizationManager.shared.localizedString("Face"))
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Gender"),
                    selectedIndex: $selectedGender,
                    items: genderOptions,
                    itemIcons: genderOptions,
                    isIconPicker: true
                )
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Skin Tone"),
                    selectedIndex: $selectedSkinTone,
                    items: skinTones,
                    isColorPicker: true
                )
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Face Shape"),
                    selectedIndex: $selectedFaceShape,
                    items: faceShapes,
                    itemIcons: faceShapeIcons
                )
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Eye Shape"),
                    selectedIndex: $selectedEyeShape,
                    items: eyeShapes,
                    itemIcons: eyeShapeIcons
                )
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Eye Color"),
                    selectedIndex: $selectedEyeColor,
                    items: eyeColors,
                    isColorPicker: true
                )
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Eyebrows"),
                    selectedIndex: $selectedEyebrows,
                    items: eyebrowStyles,
                    itemIcons: eyebrowIcons
                )
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Nose"),
                    selectedIndex: $selectedNose,
                    items: noseStyles,
                    itemIcons: noseStyleIcons
                )
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Mouth"),
                    selectedIndex: $selectedMouth,
                    items: mouthStyles,
                    itemIcons: mouthStyleIcons
                )
                if selectedGender == 0 {
                    customizationSection(
                        title: LocalizationManager.shared.localizedString("Facial Hair"),
                        selectedIndex: $selectedFacialHair,
                        items: facialHairStyles,
                        itemIcons: facialHairIcons
                    )
                }

                // MARK: - Волосы
                sectionHeader(LocalizationManager.shared.localizedString("Hair"))
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Hair Style"),
                    selectedIndex: $selectedHairStyle,
                    items: hairStyles,
                    itemIcons: hairStyleIcons
                )
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Hair Color"),
                    selectedIndex: $selectedHairColor,
                    items: hairColors,
                    isColorPicker: true
                )

                // MARK: - Головной убор и очки
                sectionHeader(LocalizationManager.shared.localizedString("Headwear & Glasses"))
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Glasses"),
                    selectedIndex: $selectedGlasses,
                    items: glassesStyles,
                    itemIcons: glassesStyleIcons
                )
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Accessories"),
                    selectedIndex: $selectedAccessory,
                    items: accessoryStyles,
                    itemIcons: accessoryStyleIcons
                )

                // MARK: - Одежда
                sectionHeader(LocalizationManager.shared.localizedString("Outfit"))
                customizationSection(
                    title: LocalizationManager.shared.localizedString("Clothing"),
                    selectedIndex: $selectedOutfit,
                    items: outfitStyles,
                    itemIcons: outfitStyleIcons
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 4)
            .padding(.top, 8)
    }
    
    // MARK: - Custom Avatar View (Improved)

    private var customAvatarView: some View {
        avatarFigure(
            skinTone: getSkinToneColor(),
            hairColor: getHairColor(),
            eyeColor: getEyeColor(),
            outfitColor: getOutfitColor()
        )
    }

    private func avatarFigure(
        skinTone: Color,
        hairColor: Color,
        eyeColor: Color,
        outfitColor: Color
    ) -> some View {
        let headW: CGFloat = 72
        let headH: CGFloat = 82
        let bodyH: CGFloat = 50
        return ZStack(alignment: .top) {
            // Тело (одежда) — трапеция/плечи
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(outfitColor)
                    .frame(width: headW * 1.35, height: bodyH)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(outfitColor.opacity(0.8), lineWidth: 1)
                    )
            }
            .offset(y: headH + 4)

            // Шея
            RoundedRectangle(cornerRadius: 4)
                .fill(skinTone.opacity(0.9))
                .frame(width: headW * 0.4, height: 14)
                .offset(y: headH - 2)

            // Голова (форма лица)
            getFaceShape()
                .fill(skinTone)
                .frame(width: headW, height: headH)
                .overlay(
                    getFaceShape()
                        .stroke(skinTone.opacity(0.7), lineWidth: 1)
                )

            // Волосы (под головной убор, над лицом)
            if selectedHairStyle > 0 {
                getHairStyle()
                    .fill(hairColor)
                    .frame(width: headW * 1.08, height: headH * 0.55)
                    .offset(y: -headH * 0.18)
            }

            // Глаза
            HStack(spacing: headW * 0.28) {
                getEyeStyle()
                    .fill(eyeColor)
                    .frame(width: 12, height: 8)
                getEyeStyle()
                    .fill(eyeColor)
                    .frame(width: 12, height: 8)
            }
            .offset(y: headH * 0.28)

            // Брови
            HStack(spacing: headW * 0.28) {
                getEyebrowStyle()
                    .fill(hairColor)
                    .frame(width: 14, height: 5)
                getEyebrowStyle()
                    .fill(hairColor)
                    .frame(width: 14, height: 5)
            }
            .offset(y: headH * 0.18)

            // Нос
            getNoseStyle()
                .fill(skinTone.opacity(0.85))
                .frame(width: 8, height: 14)
                .offset(y: headH * 0.52)

            // Рот
            getMouthStyle()
                .fill(Color.red.opacity(0.75))
                .frame(width: 22, height: 7)
                .offset(y: headH * 0.72)

            // Борода/усы (мужчины)
            if selectedGender == 0 && selectedFacialHair > 0 {
                getFacialHairStyle()
                    .fill(hairColor)
                    .frame(width: 28, height: 16)
                    .offset(y: headH * 0.82)
            }

            // Очки
            if selectedGlasses > 0 {
                getGlassesStyle()
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 56, height: 20)
                    .offset(y: headH * 0.28)
            }

            // Головной убор / аксессуар на голове
            if selectedAccessory == 1 {
                // Шляпа
                Ellipse()
                    .fill(Color.gray)
                    .frame(width: headW * 1.2, height: 18)
                    .offset(y: -headH * 0.42)
                Capsule()
                    .fill(Color.gray)
                    .frame(width: headW * 0.7, height: 22)
                    .offset(y: -headH * 0.28)
            } else if selectedAccessory == 2 {
                // Повязка
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue)
                    .frame(width: headW * 1.15, height: 12)
                    .offset(y: -headH * 0.38)
            }

            // Серьги (по бокам)
            if selectedAccessory == 3 {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .offset(x: -headW * 0.52, y: headH * 0.45)
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .offset(x: headW * 0.52, y: headH * 0.45)
            }

            // Ожерелье (у основания шеи)
            if selectedAccessory == 4 {
                Ellipse()
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: 28, height: 14)
                    .offset(y: headH + 2)
            }
        }
        .frame(width: 140, height: 160)
        .clipped()
    }
    
    // MARK: - Safe Color Access Functions
    
    private func getSkinToneColor() -> Color {
        let index = min(selectedSkinTone, skinToneColors.count - 1)
        return skinToneColors[index]
    }
    
    private func getHairColor() -> Color {
        let index = min(selectedHairColor, hairColorValues.count - 1)
        return hairColorValues[index]
    }
    
    private func getEyeColor() -> Color {
        let index = min(selectedEyeColor, eyeColorValues.count - 1)
        return eyeColorValues[index]
    }
    
    // MARK: - Improved Shape Generators
    
    private func getFaceShape() -> some Shape {
        switch selectedFaceShape {
        case 0: // Oval
            return AnyShape(Ellipse())
        case 1: // Round
            return AnyShape(Circle())
        case 2: // Square
            return AnyShape(RoundedRectangle(cornerRadius: 20))
        case 3: // Heart
            return AnyShape(HeartShape())
        default:
            return AnyShape(Ellipse())
        }
    }
    
    private func getHairStyle() -> some Shape {
        switch selectedHairStyle {
        case 1: // Short
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 110, height: 40)
                    path.addEllipse(in: rect)
                }
            )
        case 2: // Medium
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 110, height: 50)
                    path.addEllipse(in: rect)
                }
            )
        case 3: // Long
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 110, height: 70)
                    path.addEllipse(in: rect)
                }
            )
        case 4: // Curly
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 110, height: 60)
                    path.addEllipse(in: rect)
                }
            )
        case 5: // Spiky
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 110, height: 45)
                    path.addEllipse(in: rect)
                }
            )
        default:
            return AnyShape(Rectangle())
        }
    }
    
    private func getEyeStyle() -> some Shape {
        switch selectedEyeShape {
        case 0: // Round
            return AnyShape(Ellipse())
        case 1: // Almond
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 15, height: 10)
                    path.addEllipse(in: rect)
                }
            )
        case 2: // Narrow
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 15, height: 8)
                    path.addEllipse(in: rect)
                }
            )
        case 3: // Large
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 18, height: 12)
                    path.addEllipse(in: rect)
                }
            )
        case 4: // Small
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 12, height: 8)
                    path.addEllipse(in: rect)
                }
            )
        default:
            return AnyShape(Ellipse())
        }
    }
    
    private func getEyebrowStyle() -> some Shape {
        switch selectedEyebrows {
        case 0: // Straight
            return AnyShape(RoundedRectangle(cornerRadius: 2))
        case 1: // Curved
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 12, height: 6)
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 6, height: 3))
                }
            )
        case 2: // Thick
            return AnyShape(RoundedRectangle(cornerRadius: 3))
        case 3: // Thin
            return AnyShape(RoundedRectangle(cornerRadius: 1))
        case 4: // Arched
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 12, height: 6)
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 6, height: 3))
                }
            )
        default:
            return AnyShape(RoundedRectangle(cornerRadius: 2))
        }
    }
    
    private func getNoseStyle() -> some Shape {
        switch selectedNose {
        case 0: // Small
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 6, height: 10)
                    path.addEllipse(in: rect)
                }
            )
        case 1: // Medium
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 8, height: 12)
                    path.addEllipse(in: rect)
                }
            )
        case 2: // Large
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 10, height: 14)
                    path.addEllipse(in: rect)
                }
            )
        case 3: // Pointed
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 6, height: 12)
                    path.addEllipse(in: rect)
                }
            )
        case 4: // Wide
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 12, height: 10)
                    path.addEllipse(in: rect)
                }
            )
        default:
            return AnyShape(Ellipse())
        }
    }
    
    private func getMouthStyle() -> some Shape {
        switch selectedMouth {
        case 0: // Smile
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 25, height: 8)
                    path.addEllipse(in: rect)
                }
            )
        case 1: // Neutral
            return AnyShape(RoundedRectangle(cornerRadius: 3))
        case 2: // Small
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 20, height: 6)
                    path.addEllipse(in: rect)
                }
            )
        case 3: // Wide
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 30, height: 8)
                    path.addEllipse(in: rect)
                }
            )
        case 4: // Frown
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 25, height: 8)
                    path.addEllipse(in: rect)
                }
            )
        default:
            return AnyShape(Capsule())
        }
    }
    
    private func getFacialHairStyle() -> some Shape {
        switch selectedFacialHair {
        case 1: // Mustache
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 20, height: 6)
                    path.addEllipse(in: rect)
                }
            )
        case 2: // Goatee
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 16, height: 12)
                    path.addEllipse(in: rect)
                }
            )
        case 3: // Full beard
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 25, height: 18)
                    path.addEllipse(in: rect)
                }
            )
        case 4: // Stubble
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 22, height: 8)
                    path.addEllipse(in: rect)
                }
            )
        default:
            return AnyShape(Rectangle())
        }
    }
    
    private func getGlassesStyle() -> some Shape {
        switch selectedGlasses {
        case 1: // Round
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 70, height: 25)
                    path.addEllipse(in: rect)
                }
            )
        case 2: // Square
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 70, height: 25)
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 5, height: 5))
                }
            )
        case 3: // Oval
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 70, height: 25)
                    path.addEllipse(in: rect)
                }
            )
        case 4: // Sunglasses
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 70, height: 25)
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 5, height: 5))
                }
            )
        default:
            return AnyShape(Rectangle())
        }
    }
    
    private func getOutfitStyle() -> some Shape {
        switch selectedOutfit {
        case 0: // Casual
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 30, height: 25)
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 8, height: 8))
                }
            )
        case 1: // Formal
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 30, height: 25)
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 5, height: 5))
                }
            )
        case 2: // Sporty
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 30, height: 25)
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 12, height: 12))
                }
            )
        case 3: // Elegant
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 30, height: 25)
                    path.addEllipse(in: rect)
                }
            )
        case 4: // Business
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 30, height: 25)
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 10, height: 10))
                }
            )
        default:
            return AnyShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func getAccessoryStyle() -> some Shape {
        switch selectedAccessory {
        case 1: // Hat
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 25, height: 15)
                    path.addEllipse(in: rect)
                }
            )
        case 2: // Headband
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 25, height: 8)
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 6, height: 6))
                }
            )
        case 3: // Earrings
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 8, height: 8)
                    path.addEllipse(in: rect)
                }
            )
        case 4: // Necklace
            return AnyShape(
                Path { path in
                    let rect = CGRect(x: 0, y: 0, width: 20, height: 12)
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 10, height: 10))
                }
            )
        default:
            return AnyShape(Rectangle())
        }
    }
    
    private func getOutfitColor() -> Color {
        let colors = [Color.blue, Color.green, Color.red, Color.purple, Color.orange]
        return colors[selectedOutfit % colors.count]
    }
    
    // MARK: - UI Components

    private func customizationSection(
        title: String,
        selectedIndex: Binding<Int>,
        items: [String],
        itemIcons: [String]? = nil,
        isIconPicker: Bool = false,
        isColorPicker: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<items.count, id: \.self) { index in
                        Button(action: { selectedIndex.wrappedValue = index }) {
                            if isIconPicker {
                                Image(systemName: items[index])
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedIndex.wrappedValue == index ? .white : .primary)
                                    .frame(width: 50, height: 50)
                                    .background(selectedIndex.wrappedValue == index ? Color.blue : secondarySystemGroupedBackground)
                                    .cornerRadius(12)
                            } else if isColorPicker {
                                Circle()
                                    .fill(getColor(for: title, index: index))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedIndex.wrappedValue == index ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                            } else {
                                let selected = selectedIndex.wrappedValue == index
                                Group {
                                    if let icons = itemIcons, index < icons.count, !icons[index].isEmpty {
                                        Image(systemName: icons[index])
                                            .font(.system(size: 22))
                                            .foregroundColor(selected ? .blue : .primary)
                                    } else {
                                        Text(items[index])
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(selected ? .blue : .primary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                }
                                .frame(width: 50, height: 50)
                                .background(selected ? Color.blue.opacity(0.15) : secondarySystemGroupedBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selected ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    private var saveButton: some View {
        Button(action: saveAvatar) {
            Text(LocalizationManager.shared.localizedString("Save Avatar"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private func saveAvatar() {
        #if os(iOS)
        if selectedTab == 0, let image = selectedImage,
           let data = image.jpegData(compressionQuality: 0.9) {
            userProfile.customAvatarImageData = data
            userProfile.avatar = "custom_photo"
        } else if selectedTab == 1 {
            if let data = renderCreatedAvatarToImage() {
                userProfile.customAvatarImageData = data
                userProfile.avatar = "custom_photo"
            }
        }

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #else
        if selectedTab == 1, let data = renderCreatedAvatarToImage() {
            userProfile.customAvatarImageData = data
            userProfile.avatar = "custom_photo"
        }
        #endif

        presentationMode.wrappedValue.dismiss()
    }

    #if os(iOS)
    private func renderCreatedAvatarToImage() -> Data? {
        let view = AvatarSnapshotView(
            selectedGender: selectedGender,
            selectedSkinTone: selectedSkinTone,
            selectedFaceShape: selectedFaceShape,
            selectedHairStyle: selectedHairStyle,
            selectedHairColor: selectedHairColor,
            selectedEyeShape: selectedEyeShape,
            selectedEyeColor: selectedEyeColor,
            selectedEyebrows: selectedEyebrows,
            selectedNose: selectedNose,
            selectedMouth: selectedMouth,
            selectedFacialHair: selectedFacialHair,
            selectedOutfit: selectedOutfit,
            selectedAccessory: selectedAccessory,
            selectedGlasses: selectedGlasses
        )
        let size = CGSize(width: 280, height: 320)
        let hosting = UIHostingController(rootView: view.frame(width: size.width, height: size.height))
        hosting.view.bounds = CGRect(origin: .zero, size: size)
        hosting.view.backgroundColor = .clear
        hosting.view.layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            hosting.view.layer.render(in: ctx.cgContext)
        }
        return image.jpegData(compressionQuality: 0.9)
    }
    #else
    private func renderCreatedAvatarToImage() -> Data? { nil }
    #endif
    
    // MARK: - Helper Functions
    
    private func getColor(for category: String, index: Int) -> Color {
        switch category {
        case LocalizationManager.shared.localizedString("Skin Tone"):
            return skinToneColors[index]
        case LocalizationManager.shared.localizedString("Hair Color"):
            return hairColorValues[index]
        case LocalizationManager.shared.localizedString("Eye Color"):
            return eyeColorValues[index]
        default:
            return .gray
        }
    }
    
    // MARK: - Avatar Customization Data

    private let genderOptions = ["person.fill", "person.crop.circle.fill"]

    private let skinTones = ["Very Light", "Light", "Medium", "Tan", "Dark", "Very Dark"]
    private let faceShapeIcons = ["oval", "circle.fill", "square.fill", "heart.fill"]
    private let eyeShapeIcons = ["eye.fill", "eye", "eye.trianglebadge.exclamationmark", "eye.circle", "eye.slash"]
    private let eyebrowIcons = ["line.diagonal", "curlybraces", "bold", "italic", "arrow.up"]
    private let noseStyleIcons = ["circle.fill", "circle.lefthalf.filled", "circle", "location.north.fill", "square.fill"]
    private let mouthStyleIcons = ["face.smiling.fill", "minus", "circle.fill", "rectangle.compress.vertical", "mouth"]
    private let facialHairIcons = ["xmark.circle", "mustache.fill", "rectangle.fill", "person.fill", "circle.lefthalf.filled"]
    private let hairStyleIcons = ["person.crop.circle", "scissors", "wind", "waveform.path", "flame", "bolt.fill"]
    private let glassesStyleIcons = ["xmark.circle", "eyeglasses", "rectangle", "oval", "sun.max.fill"]
    private let accessoryStyleIcons = ["xmark.circle", "graduationcap.fill", "bandage", "circle.fill", "link"]
    private let outfitStyleIcons = ["tshirt.fill", "suit.club.fill", "figure.run", "sparkles", "briefcase.fill"]
    private let skinToneColors = [
        Color(red: 1.0, green: 0.87, blue: 0.73),
        Color(red: 0.96, green: 0.80, blue: 0.69),
        Color(red: 0.85, green: 0.65, blue: 0.47),
        Color(red: 0.73, green: 0.51, blue: 0.37),
        Color(red: 0.55, green: 0.35, blue: 0.25),
        Color(red: 0.35, green: 0.20, blue: 0.15)
    ]
    
    private let faceShapes = ["Oval", "Round", "Square", "Heart"]
    
    private let hairStyles = ["Bald", "Short", "Medium", "Long", "Curly", "Spiky"]
    private let hairColors = ["Black", "Brown", "Blonde", "Red", "Gray", "White", "Blue"]
    private let hairColorValues = [
        Color.black,
        Color.brown,
        Color.yellow,
        Color.red,
        Color.gray,
        Color.white,
        Color.blue
    ]
    
    private let eyeShapes = ["Round", "Almond", "Narrow", "Large", "Small"]
    private let eyeColors = ["Brown", "Blue", "Green", "Hazel", "Gray", "Black"]
    private let eyeColorValues = [
        Color.brown,
        Color.blue,
        Color.green,
        Color(red: 0.6, green: 0.4, blue: 0.2),
        Color.gray,
        Color.black
    ]
    
    private let eyebrowStyles = ["Straight", "Curved", "Thick", "Thin", "Arched"]
    private let noseStyles = ["Small", "Medium", "Large", "Pointed", "Wide"]
    private let mouthStyles = ["Smile", "Neutral", "Small", "Wide", "Frown"]
    private let facialHairStyles = ["None", "Mustache", "Goatee", "Full Beard", "Stubble"]
    private let glassesStyles = ["None", "Round", "Square", "Oval", "Sunglasses"]
    private let outfitStyles = ["Casual", "Formal", "Sporty", "Elegant", "Business"]
    private let accessoryStyles = ["None", "Hat", "Headband", "Earrings", "Necklace"]
}

// MARK: - Snapshot view for rendering created avatar to image
#if os(iOS)
struct AvatarSnapshotView: View {
    let selectedGender: Int
    let selectedSkinTone: Int
    let selectedFaceShape: Int
    let selectedHairStyle: Int
    let selectedHairColor: Int
    let selectedEyeShape: Int
    let selectedEyeColor: Int
    let selectedEyebrows: Int
    let selectedNose: Int
    let selectedMouth: Int
    let selectedFacialHair: Int
    let selectedOutfit: Int
    let selectedAccessory: Int
    let selectedGlasses: Int

    private static let skinToneColors: [Color] = [
        Color(red: 1.0, green: 0.87, blue: 0.73),
        Color(red: 0.96, green: 0.80, blue: 0.69),
        Color(red: 0.85, green: 0.65, blue: 0.47),
        Color(red: 0.73, green: 0.51, blue: 0.37),
        Color(red: 0.55, green: 0.35, blue: 0.25),
        Color(red: 0.35, green: 0.20, blue: 0.15)
    ]
    private static let hairColorValues: [Color] = [
        .black, .brown, .yellow, .red, .gray, .white, .blue
    ]
    private static let eyeColorValues: [Color] = [
        .brown, .blue, .green, Color(red: 0.6, green: 0.4, blue: 0.2), .gray, .black
    ]
    private static let outfitColors: [Color] = [.blue, .green, .red, .purple, .orange]

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            snapshotFigure
        }
    }

    private var snapshotFigure: some View {
        let skinTone = Self.skinToneColors[min(selectedSkinTone, Self.skinToneColors.count - 1)]
        let hairColor = Self.hairColorValues[min(selectedHairColor, Self.hairColorValues.count - 1)]
        let eyeColor = Self.eyeColorValues[min(selectedEyeColor, Self.eyeColorValues.count - 1)]
        let outfitColor = Self.outfitColors[selectedOutfit % Self.outfitColors.count]
        let headW: CGFloat = 72
        let headH: CGFloat = 82
        let bodyH: CGFloat = 50
        return ZStack(alignment: .top) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(outfitColor)
                    .frame(width: headW * 1.35, height: bodyH)
            }
            .offset(y: headH + 4)
            RoundedRectangle(cornerRadius: 4)
                .fill(skinTone.opacity(0.9))
                .frame(width: headW * 0.4, height: 14)
                .offset(y: headH - 2)
            snapshotFaceShape()
                .fill(skinTone)
                .frame(width: headW, height: headH)
            if selectedHairStyle > 0 {
                snapshotHairShape()
                    .fill(hairColor)
                    .frame(width: headW * 1.08, height: headH * 0.55)
                    .offset(y: -headH * 0.18)
            }
            HStack(spacing: headW * 0.28) {
                snapshotEyeShape().fill(eyeColor).frame(width: 12, height: 8)
                snapshotEyeShape().fill(eyeColor).frame(width: 12, height: 8)
            }
            .offset(y: headH * 0.28)
            HStack(spacing: headW * 0.28) {
                snapshotEyebrowShape().fill(hairColor).frame(width: 14, height: 5)
                snapshotEyebrowShape().fill(hairColor).frame(width: 14, height: 5)
            }
            .offset(y: headH * 0.18)
            snapshotNoseShape()
                .fill(skinTone.opacity(0.85))
                .frame(width: 8, height: 14)
                .offset(y: headH * 0.52)
            snapshotMouthShape()
                .fill(Color.red.opacity(0.75))
                .frame(width: 22, height: 7)
                .offset(y: headH * 0.72)
            if selectedGender == 0 && selectedFacialHair > 0 {
                snapshotFacialHairShape()
                    .fill(hairColor)
                    .frame(width: 28, height: 16)
                    .offset(y: headH * 0.82)
            }
            if selectedGlasses > 0 {
                snapshotGlassesShape()
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 56, height: 20)
                    .offset(y: headH * 0.28)
            }
            if selectedAccessory == 1 {
                Ellipse().fill(Color.gray).frame(width: headW * 1.2, height: 18).offset(y: -headH * 0.42)
                Capsule().fill(Color.gray).frame(width: headW * 0.7, height: 22).offset(y: -headH * 0.28)
            } else if selectedAccessory == 2 {
                RoundedRectangle(cornerRadius: 6).fill(Color.blue).frame(width: headW * 1.15, height: 12).offset(y: -headH * 0.38)
            }
            if selectedAccessory == 3 {
                Circle().fill(Color.gray).frame(width: 8, height: 8).offset(x: -headW * 0.52, y: headH * 0.45)
                Circle().fill(Color.gray).frame(width: 8, height: 8).offset(x: headW * 0.52, y: headH * 0.45)
            }
            if selectedAccessory == 4 {
                Ellipse().stroke(Color.gray, lineWidth: 2).frame(width: 28, height: 14).offset(y: headH + 2)
            }
        }
        .frame(width: 140, height: 160)
    }

    private func snapshotFaceShape() -> AnyShape {
        switch selectedFaceShape {
        case 0: return AnyShape(Ellipse())
        case 1: return AnyShape(Circle())
        case 2: return AnyShape(RoundedRectangle(cornerRadius: 20))
        case 3: return AnyShape(HeartShape())
        default: return AnyShape(Ellipse())
        }
    }
    private func snapshotHairShape() -> AnyShape {
        switch selectedHairStyle {
        case 1...5: return AnyShape(Ellipse())
        default: return AnyShape(Rectangle())
        }
    }
    private func snapshotEyeShape() -> AnyShape { AnyShape(Ellipse()) }
    private func snapshotEyebrowShape() -> AnyShape { AnyShape(RoundedRectangle(cornerRadius: 2)) }
    private func snapshotNoseShape() -> AnyShape { AnyShape(Ellipse()) }
    private func snapshotMouthShape() -> AnyShape { AnyShape(Capsule()) }
    private func snapshotFacialHairShape() -> AnyShape { AnyShape(Ellipse()) }
    private func snapshotGlassesShape() -> AnyShape { AnyShape(Ellipse()) }
}
#endif

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.8))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.3), control1: CGPoint(x: w * 0.2, y: h * 0.6), control2: CGPoint(x: 0, y: h * 0.5))
        path.addCurve(to: CGPoint(x: w * 0.5, y: 0), control1: CGPoint(x: 0, y: h * 0.1), control2: CGPoint(x: w * 0.2, y: 0))
        path.addCurve(to: CGPoint(x: w, y: h * 0.3), control1: CGPoint(x: w * 0.8, y: 0), control2: CGPoint(x: w, y: h * 0.1))
        path.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.8), control1: CGPoint(x: w, y: h * 0.5), control2: CGPoint(x: w * 0.8, y: h * 0.6))
        return path
    }
}

// MARK: - AnyShape Wrapper
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - ImagePicker
#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
#endif

#Preview {
    AvatarEditorView()
        .environmentObject(UserProfile.shared)
}