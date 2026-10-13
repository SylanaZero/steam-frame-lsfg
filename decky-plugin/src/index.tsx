import {
  definePlugin,
  PanelSection,
  PanelSectionRow,
  ToggleField,
  SliderField,
  Field,
  ServerAPI,
  staticClasses,
} from "decky-frontend-lib";
import { VFC, useState, useEffect } from "react";
import { FaBolt, FaCheckCircle, FaExclamationTriangle } from "react-icons/fa";

interface LSFGStatus {
  dll_found: boolean;
  dll_path: string;
  aurora_found?: boolean;
  config: {
    enabled: boolean;
    multiplier: number;
    flow_scale: number;
    performance_mode: boolean;
    sync_to_display: boolean;
  };
  hardware: string;
}

const Content: VFC<{ serverApi: ServerAPI }> = ({ serverApi }) => {
  const [status, setStatus] = useState<LSFGStatus | null>(null);
  const [enabled, setEnabled] = useState<boolean>(true);
  const [multiplier, setMultiplier] = useState<number>(2);
  const [flowScale, setFlowScale] = useState<number>(0.75);
  const [perfMode, setPerfMode] = useState<boolean>(true);

  const loadStatus = async () => {
    try {
      const res = await serverApi.callPluginMethod<{}, LSFGStatus>("get_status", {});
      if (res.success && res.result) {
        setStatus(res.result);
        setEnabled(res.result.config.enabled);
        setMultiplier(res.result.config.multiplier);
        setFlowScale(res.result.config.flow_scale);
        setPerfMode(res.result.config.performance_mode);
      }
    } catch (err) {
      console.error("[SteamFrame-LSFG] Error fetching status:", err);
    }
  };

  useEffect(() => {
    loadStatus();
  }, []);

  const saveSettings = async (newSettings: {
    enabled: boolean;
    multiplier: number;
    flow_scale: number;
    performance_mode: boolean;
    sync_to_display: boolean;
  }) => {
    try {
      await serverApi.callPluginMethod("save_config", {
        app_id: 0,
        settings: newSettings,
      });
    } catch (err) {
      console.error("[SteamFrame-LSFG] Error saving config:", err);
    }
  };

  const handleToggleEnabled = (val: boolean) => {
    setEnabled(val);
    saveSettings({ enabled: val, multiplier, flow_scale: flowScale, performance_mode: perfMode, sync_to_display: true });
  };

  const handleMultiplierChange = (val: number) => {
    setMultiplier(val);
    saveSettings({ enabled, multiplier: val, flow_scale: flowScale, performance_mode: perfMode, sync_to_display: true });
  };

  const handleFlowScaleChange = (val: number) => {
    setFlowScale(val);
    saveSettings({ enabled, multiplier, flow_scale: val, performance_mode: perfMode, sync_to_display: true });
  };

  const handleTogglePerfMode = (val: boolean) => {
    setPerfMode(val);
    saveSettings({ enabled, multiplier, flow_scale: flowScale, performance_mode: val, sync_to_display: true });
  };

  return (
    <PanelSection title="Lossless Scaling (LSFG)">
      <PanelSectionRow>
        <Field
          label="Engine Status"
          description={
            status?.dll_found
              ? "lsfg-vk.dll verified & loaded"
              : "lsfg-vk.dll missing (Steam App 993090 'lsfg-vk' beta branch required)"
          }
          icon={
            status?.dll_found ? (
              <FaCheckCircle style={{ color: "#4CAF50" }} />
            ) : (
              <FaExclamationTriangle style={{ color: "#FF9800" }} />
            )
          }
        />
      </PanelSectionRow>

      <PanelSectionRow>
        <Field
          label="Turnip Driver"
          description={
            status?.aurora_found
              ? "Balemuni's Aurora (Apex Universal) Active"
              : "System Mesa Turnip (Run install-turnip-aurora.sh for optimal performance)"
          }
          icon={
            status?.aurora_found ? (
              <FaCheckCircle style={{ color: "#4CAF50" }} />
            ) : (
              <FaCheckCircle style={{ color: "#2196F3" }} />
            )
          }
        />
      </PanelSectionRow>

      <PanelSectionRow>
        <ToggleField
          label="Enable Frame Generation"
          description="Intercept Vulkan presentation & interpolate frames"
          checked={enabled}
          onChange={handleToggleEnabled}
        />
      </PanelSectionRow>

      {enabled && (
        <>
          <PanelSectionRow>
            <SliderField
              label="Multiplier"
              description={`${multiplier}x Target Frame Rate (${multiplier === 2 ? "45->90 / 60->120" : multiplier === 3 ? "30->90 / 40->120" : "36->144"})`}
              value={multiplier}
              min={2}
              max={4}
              step={1}
              showValue
              onChange={handleMultiplierChange}
            />
          </PanelSectionRow>

          <PanelSectionRow>
            <SliderField
              label="Flow Scale"
              description="Optical flow calculation resolution"
              value={Math.round(flowScale * 100)}
              min={50}
              max={100}
              step={5}
              showValue
              valueSuffix="%"
              onChange={(val) => handleFlowScaleChange(val / 100)}
            />
          </PanelSectionRow>

          <PanelSectionRow>
            <ToggleField
              label="Adreno 750 Performance Mode"
              description="Fast FP16 shaders & reduced thermal throttle risk"
              checked={perfMode}
              onChange={handleTogglePerfMode}
            />
          </PanelSectionRow>
        </>
      )}

      <PanelSectionRow>
        <div style={{ fontSize: "11px", color: "#888", padding: "4px 8px" }}>
          Target: Valve Steam Frame | Adreno 750 / Turnip
        </div>
      </PanelSectionRow>
    </PanelSection>
  );
};

export default definePlugin((serverApi: ServerAPI) => {
  return {
    title: <div className={staticClasses.Title}>Steam Frame LSFG</div>,
    content: <Content serverApi={serverApi} />,
    icon: <FaBolt />,
    onDismount() {},
  };
});
