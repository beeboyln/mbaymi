import ParcelWorkspace from "@/components/parcel-workspace";

export default async function RemindersPage({ params }: { params: Promise<{ farmId: string; cropId: string }> }) {
  const { farmId, cropId } = await params;
  return <ParcelWorkspace mode="reminders" farmId={Number(farmId)} cropId={Number(cropId)} />;
}
