import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    var foregroundColor: Color = .fullioSoftGreen
    var backgroundColor: Color = .fullioSoftGreen.opacity(0.15)

    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    foregroundColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

struct GoalProgressCard: View {
    let goal: SavingsGoal

    var body: some View {
        HStack(spacing: FullioSpacing.md) {
            ZStack {
                ProgressRing(
                    progress: goal.progress,
                    lineWidth: 6,
                    size: 52
                )

                Image(systemName: goal.icon)
                    .font(.body)
                    .foregroundStyle(.fullioDarkGreen)
            }

            VStack(alignment: .leading, spacing: FullioSpacing.xs) {
                Text(goal.name)
                    .font(FullioFont.body(15).weight(.semibold))
                    .foregroundStyle(.fullioBlack)

                Text("\(Int(goal.currentAmount))€ / \(Int(goal.targetAmount))€")
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioSecondaryText)

                Text(goal.estimatedCompletionMessage)
                    .font(FullioFont.body(12))
                    .foregroundStyle(.fullioSoftGreen)
            }

            Spacer()

            Text(goal.formattedProgress)
                .font(FullioFont.smallNumber(16))
                .foregroundStyle(.fullioDarkGreen)
        }
        .fullioCard(padding: FullioSpacing.md)
    }
}

#Preview {
    VStack {
        ProgressRing(progress: 0.65, lineWidth: 8, size: 80)

        ForEach(SavingsGoal.sampleGoals) { goal in
            GoalProgressCard(goal: goal)
        }
    }
    .padding()
    .background(Color.fullioBackground)
}
