import ParcelWorkspace from "@/components/parcel-workspace";

export default async function ProblemsPage({ params }: { params: Promise<{ farmId: string; cropId: string }> }) {
  const { farmId, cropId } = await params;
  return <ParcelWorkspace mode="problems" farmId={Number(farmId)} cropId={Number(cropId)} />;
}
