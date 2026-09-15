import ParcelWorkspace from "@/components/parcel-workspace";

export default async function ActivityPage({ params }: { params: Promise<{ farmId: string; cropId: string }> }) {
  const { farmId, cropId } = await params;
  return <ParcelWorkspace mode="activity" farmId={Number(farmId)} cropId={Number(cropId)} />;
}
