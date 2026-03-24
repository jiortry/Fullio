import SwiftUI

struct UpdateView: View {
    @State private var configManager = RemoteConfigManager.shared
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.fullioBackground
                .ignoresSafeArea()

            VStack(spacing: FullioSpacing.xl) {
                Spacer()

                updateIcon

                VStack(spacing: FullioSpacing.sm) {
                    Text("Aggiornamento disponibile")
                        .font(FullioFont.title(24))
                        .foregroundStyle(.fullioBlack)
                        .multilineTextAlignment(.center)

                    if let remote = configManager.remoteVersion {
                        Text("Versione \(remote.version)")
                            .font(FullioFont.headline(16))
                            .foregroundStyle(.fullioSoftGreen)
                    }

                    Text(changelogText)
                        .font(FullioFont.body(14))
                        .foregroundStyle(.fullioSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FullioSpacing.xl)
                }

                if configManager.isDownloading {
                    downloadProgressView
                } else if configManager.downloadProgress >= 1.0 {
                    successView
                } else {
                    actionButtons
                }

                if let error = configManager.lastError {
                    Text(error)
                        .font(FullioFont.caption())
                        .foregroundStyle(.fullioWarning)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
        }
    }

    private var changelogText: String {
        configManager.remoteVersion?.changelog
            ?? "Nuova configurazione disponibile. Aggiorna per ottenere le ultime modifiche."
    }

    private var updateIcon: some View {
        ZStack {
            Circle()
                .fill(Color.fullioLightGreen)
                .frame(width: 120, height: 120)

            Circle()
                .fill(Color.fullioDarkGreen)
                .frame(width: 80, height: 80)

            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.white)
        }
    }

    private var downloadProgressView: some View {
        VStack(spacing: FullioSpacing.md) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: FullioRadius.full)
                    .fill(Color.fullioLightGreen)
                    .frame(height: 8)

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: FullioRadius.full)
                        .fill(Color.fullioDarkGreen)
                        .frame(width: geo.size.width * configManager.downloadProgress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: configManager.downloadProgress)
                }
                .frame(height: 8)
            }
            .frame(width: 260)

            Text("Download in corso... \(Int(configManager.downloadProgress * 100))%")
                .font(FullioFont.caption())
                .foregroundStyle(.fullioSecondaryText)
        }
    }

    private var successView: some View {
        VStack(spacing: FullioSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.fullioSoftGreen)

            Text("Aggiornamento completato!")
                .font(FullioFont.headline(16))
                .foregroundStyle(.fullioDarkGreen)

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            } label: {
                Text("Continua")
                    .font(FullioFont.headline(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FullioSpacing.md)
                    .background(Color.fullioDarkGreen)
                    .clipShape(RoundedRectangle(cornerRadius: FullioRadius.md))
            }
            .padding(.horizontal, FullioSpacing.xl)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: FullioSpacing.sm) {
            Button {
                Task {
                    await configManager.downloadUpdate()
                }
            } label: {
                HStack(spacing: FullioSpacing.sm) {
                    Image(systemName: "arrow.down.to.line")
                    Text("Scarica aggiornamento")
                }
                .font(FullioFont.headline(16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FullioSpacing.md)
                .background(Color.fullioDarkGreen)
                .clipShape(RoundedRectangle(cornerRadius: FullioRadius.md))
            }
            .padding(.horizontal, FullioSpacing.xl)

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            } label: {
                Text("Più tardi")
                    .font(FullioFont.body(14))
                    .foregroundStyle(.fullioSecondaryText)
            }
        }
    }
}
