import ParcelWorkspace from "@/components/parcel-workspace";

export default async function FinancePage({ params }: { params: Promise<{ farmId: string; cropId: string }> }) {
  const { farmId, cropId } = await params;
  return <ParcelWorkspace mode="finance" farmId={Number(farmId)} cropId={Number(cropId)} />;
}
