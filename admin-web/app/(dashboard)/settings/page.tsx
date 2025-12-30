"use client";

import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/components/ui/use-toast";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Skeleton } from "@/components/ui/skeleton";
import { getUserFromToken } from "@/lib/auth";
import { Save, RefreshCw } from "lucide-react";

interface Setting {
  _id?: string;
  key: string;
  value: any;
  description?: string;
  category: string;
}

async function fetchSettings(): Promise<Setting[]> {
  const token = document.cookie
    .split("; ")
    .find((row) => row.startsWith("access_token="))
    ?.split("=")[1];

  const res = await fetch("/api/settings", {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!res.ok) throw new Error("Failed to fetch settings");
  return res.json();
}

async function updateSettings(settings: Array<{ key: string; value: any }>): Promise<void> {
  const token = document.cookie
    .split("; ")
    .find((row) => row.startsWith("access_token="))
    ?.split("=")[1];

  const res = await fetch("/api/settings", {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ settings }),
  });

  if (!res.ok) {
    const error = await res.json().catch(() => ({}));
    throw new Error(error.message || "Failed to update settings");
  }
}

export default function SettingsPage() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const user = getUserFromToken();
  const [settings, setSettings] = useState<Record<string, any>>({});
  const [hasChanges, setHasChanges] = useState(false);

  const { data: allSettings = [], isLoading } = useQuery<Setting[]>({
    queryKey: ["settings"],
    queryFn: fetchSettings,
  });

  const updateMutation = useMutation({
    mutationFn: updateSettings,
    onSuccess: () => {
      toast({
        title: "Settings updated",
        description: "Your changes have been saved successfully.",
      });
      queryClient.invalidateQueries({ queryKey: ["settings"] });
      setHasChanges(false);
    },
    onError: (error: Error) => {
      toast({
        title: "Error",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  useEffect(() => {
    if (allSettings.length > 0) {
      const settingsMap: Record<string, any> = {};
      allSettings.forEach((setting) => {
        settingsMap[setting.key] = setting.value;
      });
      setSettings(settingsMap);
    }
  }, [allSettings]);

  const handleChange = (key: string, value: any) => {
    setSettings((prev) => ({ ...prev, [key]: value }));
    setHasChanges(true);
  };

  const handleSave = () => {
    const settingsArray = Object.entries(settings).map(([key, value]) => ({
      key,
      value,
    }));
    updateMutation.mutate(settingsArray);
  };

  const handleReset = () => {
    const settingsMap: Record<string, any> = {};
    allSettings.forEach((setting) => {
      settingsMap[setting.key] = setting.value;
    });
    setSettings(settingsMap);
    setHasChanges(false);
  };

  const isAdmin = user?.roles?.includes("ADMIN");

  if (!isAdmin) {
    return (
      <div className="flex flex-col items-center justify-center h-full">
        <h2 className="text-xl font-semibold mb-2">Access Denied</h2>
        <p className="text-muted-foreground">You do not have permission to view this page.</p>
      </div>
    );
  }

  const emailSettings = allSettings.filter((s) => s.category === "email");
  const notificationSettings = allSettings.filter((s) => s.category === "notification");
  const workflowSettings = allSettings.filter((s) => s.category === "workflow");
  const systemSettings = allSettings.filter((s) => s.category === "system");
  const vehicleSettings = allSettings.filter((s) => s.category === "vehicle");

  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">System Settings</h1>
          <p className="text-muted-foreground">Configure system-wide settings and preferences</p>
        </div>
        <div className="flex gap-2">
          {hasChanges && (
            <Button variant="outline" onClick={handleReset} disabled={updateMutation.isPending}>
              <RefreshCw className="mr-2 h-4 w-4" />
              Reset
            </Button>
          )}
          <Button onClick={handleSave} disabled={!hasChanges || updateMutation.isPending}>
            <Save className="mr-2 h-4 w-4" />
            Save Changes
          </Button>
        </div>
      </div>

      {isLoading ? (
        <div className="space-y-4">
          <Skeleton className="h-64 w-full" />
          <Skeleton className="h-64 w-full" />
        </div>
      ) : (
        <Tabs defaultValue="email" className="space-y-4">
          <TabsList>
            <TabsTrigger value="email">Email</TabsTrigger>
            <TabsTrigger value="notification">Notifications</TabsTrigger>
            <TabsTrigger value="workflow">Workflow</TabsTrigger>
            <TabsTrigger value="vehicle">Vehicle</TabsTrigger>
            <TabsTrigger value="system">System</TabsTrigger>
          </TabsList>

          <TabsContent value="email" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>Email Configuration</CardTitle>
                <CardDescription>Configure email notification settings</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {emailSettings.map((setting) => (
                  <div key={setting.key} className="space-y-2">
                    <Label htmlFor={setting.key}>
                      {setting.key.replace("email.", "").replace(/_/g, " ").replace(/\b\w/g, (l) => l.toUpperCase())}
                    </Label>
                    {typeof setting.value === "boolean" ? (
                      <div className="flex items-center space-x-2">
                        <Switch
                          id={setting.key}
                          checked={settings[setting.key] ?? setting.value}
                          onCheckedChange={(checked) => handleChange(setting.key, checked)}
                        />
                        <Label htmlFor={setting.key} className="cursor-pointer">
                          {settings[setting.key] ?? setting.value ? "Enabled" : "Disabled"}
                        </Label>
                      </div>
                    ) : (
                      <Input
                        id={setting.key}
                        value={settings[setting.key] ?? setting.value ?? ""}
                        onChange={(e) => handleChange(setting.key, e.target.value)}
                      />
                    )}
                    {setting.description && (
                      <p className="text-sm text-muted-foreground">{setting.description}</p>
                    )}
                  </div>
                ))}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="notification" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>Notification Settings</CardTitle>
                <CardDescription>Configure notification preferences</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {notificationSettings.map((setting) => (
                  <div key={setting.key} className="space-y-2">
                    <Label htmlFor={setting.key}>
                      {setting.key
                        .replace("notification.", "")
                        .replace(/_/g, " ")
                        .replace(/\b\w/g, (l) => l.toUpperCase())}
                    </Label>
                    {typeof setting.value === "boolean" ? (
                      <div className="flex items-center space-x-2">
                        <Switch
                          id={setting.key}
                          checked={settings[setting.key] ?? setting.value}
                          onCheckedChange={(checked) => handleChange(setting.key, checked)}
                        />
                        <Label htmlFor={setting.key} className="cursor-pointer">
                          {settings[setting.key] ?? setting.value ? "Enabled" : "Disabled"}
                        </Label>
                      </div>
                    ) : (
                      <Input
                        id={setting.key}
                        value={settings[setting.key] ?? setting.value ?? ""}
                        onChange={(e) => handleChange(setting.key, e.target.value)}
                      />
                    )}
                    {setting.description && (
                      <p className="text-sm text-muted-foreground">{setting.description}</p>
                    )}
                  </div>
                ))}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="workflow" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>Workflow Configuration</CardTitle>
                <CardDescription>Configure workflow behavior</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {workflowSettings.map((setting) => (
                  <div key={setting.key} className="space-y-2">
                    <Label htmlFor={setting.key}>
                      {setting.key
                        .replace("workflow.", "")
                        .replace(/_/g, " ")
                        .replace(/\b\w/g, (l) => l.toUpperCase())}
                    </Label>
                    {typeof setting.value === "boolean" ? (
                      <div className="flex items-center space-x-2">
                        <Switch
                          id={setting.key}
                          checked={settings[setting.key] ?? setting.value}
                          onCheckedChange={(checked) => handleChange(setting.key, checked)}
                        />
                        <Label htmlFor={setting.key} className="cursor-pointer">
                          {settings[setting.key] ?? setting.value ? "Enabled" : "Disabled"}
                        </Label>
                      </div>
                    ) : (
                      <Input
                        id={setting.key}
                        value={settings[setting.key] ?? setting.value ?? ""}
                        onChange={(e) => handleChange(setting.key, e.target.value)}
                      />
                    )}
                    {setting.description && (
                      <p className="text-sm text-muted-foreground">{setting.description}</p>
                    )}
                  </div>
                ))}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="vehicle" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>Vehicle Configuration</CardTitle>
                <CardDescription>Configure vehicle-related settings</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {vehicleSettings.map((setting) => (
                  <div key={setting.key} className="space-y-2">
                    <Label htmlFor={setting.key}>
                      {setting.key
                        .replace("fuel_consumption_mpg", "Fuel Consumption (MPG)")
                        .replace(/_/g, " ")
                        .replace(/\b\w/g, (l) => l.toUpperCase())}
                    </Label>
                    {typeof setting.value === "boolean" ? (
                      <div className="flex items-center space-x-2">
                        <Switch
                          id={setting.key}
                          checked={settings[setting.key] ?? setting.value}
                          onCheckedChange={(checked) => handleChange(setting.key, checked)}
                        />
                        <Label htmlFor={setting.key} className="cursor-pointer">
                          {settings[setting.key] ?? setting.value ? "Enabled" : "Disabled"}
                        </Label>
                      </div>
                    ) : typeof setting.value === "number" ? (
                      <Input
                        id={setting.key}
                        type="number"
                        min="1"
                        step="0.1"
                        value={settings[setting.key] ?? setting.value ?? ""}
                        onChange={(e) => handleChange(setting.key, parseFloat(e.target.value) || 0)}
                      />
                    ) : (
                      <Input
                        id={setting.key}
                        value={settings[setting.key] ?? setting.value ?? ""}
                        onChange={(e) => handleChange(setting.key, e.target.value)}
                      />
                    )}
                    {setting.description && (
                      <p className="text-sm text-muted-foreground">{setting.description}</p>
                    )}
                  </div>
                ))}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="system" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>System Preferences</CardTitle>
                <CardDescription>Configure system-wide settings</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {systemSettings.map((setting) => (
                  <div key={setting.key} className="space-y-2">
                    <Label htmlFor={setting.key}>
                      {setting.key
                        .replace("system.", "")
                        .replace(/_/g, " ")
                        .replace(/\b\w/g, (l) => l.toUpperCase())}
                    </Label>
                    {typeof setting.value === "boolean" ? (
                      <div className="flex items-center space-x-2">
                        <Switch
                          id={setting.key}
                          checked={settings[setting.key] ?? setting.value}
                          onCheckedChange={(checked) => handleChange(setting.key, checked)}
                        />
                        <Label htmlFor={setting.key} className="cursor-pointer">
                          {settings[setting.key] ?? setting.value ? "Enabled" : "Disabled"}
                        </Label>
                      </div>
                    ) : (
                      <Input
                        id={setting.key}
                        value={settings[setting.key] ?? setting.value ?? ""}
                        onChange={(e) => handleChange(setting.key, e.target.value)}
                      />
                    )}
                    {setting.description && (
                      <p className="text-sm text-muted-foreground">{setting.description}</p>
                    )}
                  </div>
                ))}
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      )}
    </div>
  );
}
