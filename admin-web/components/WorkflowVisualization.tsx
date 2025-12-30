'use client'

import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { CheckCircle2, Circle, Clock } from 'lucide-react'
import { cn } from '@/lib/utils'

interface WorkflowStage {
  stage: string
  role: string | null
  description: string
}

interface Approval {
  approverId: string
  role: string
  status: 'APPROVED' | 'REJECTED'
  comment?: string
  timestamp: string
}

interface WorkflowVisualizationProps {
  currentStage: string
  workflowStages: WorkflowStage[]
  approvals: Approval[]
}

export default function WorkflowVisualization({
  currentStage,
  workflowStages,
  approvals,
}: WorkflowVisualizationProps) {
  const getStageStatus = (stage: string) => {
    const currentIndex = workflowStages.findIndex((s) => s.stage === currentStage)
    const stageIndex = workflowStages.findIndex((s) => s.stage === stage)

    if (stageIndex < currentIndex) {
      return 'completed'
    } else if (stageIndex === currentIndex) {
      return 'current'
    } else {
      return 'pending'
    }
  }

  const getApprovalForStage = (stage: string) => {
    return approvals.find((approval) => {
      // Find the workflow stage that matches this approval
      const stageInfo = workflowStages.find((s) => s.stage === stage)
      return stageInfo && approval.role === stageInfo.role
    })
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Workflow Progress</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {workflowStages.map((stage, index) => {
            const status = getStageStatus(stage.stage)
            const approval = getApprovalForStage(stage.stage)
            const isLast = index === workflowStages.length - 1

            return (
              <div key={stage.stage} className="relative">
                {!isLast && (
                  <div
                    className={cn(
                      'absolute left-5 top-10 w-0.5 h-8',
                      status === 'completed' ? 'bg-primary' : 'bg-muted'
                    )}
                  />
                )}
                <div className="flex items-start gap-4">
                  <div
                    className={cn(
                      'flex items-center justify-center w-10 h-10 rounded-full border-2',
                      status === 'completed'
                        ? 'bg-primary border-primary text-primary-foreground'
                        : status === 'current'
                          ? 'bg-primary/10 border-primary text-primary'
                          : 'bg-muted border-muted-foreground/20 text-muted-foreground'
                    )}
                  >
                    {status === 'completed' ? (
                      <CheckCircle2 className="h-5 w-5" />
                    ) : status === 'current' ? (
                      <Clock className="h-5 w-5" />
                    ) : (
                      <Circle className="h-5 w-5" />
                    )}
                  </div>
                  <div className="flex-1 space-y-1">
                    <div className="flex items-center gap-2">
                      <h4 className="font-semibold">{stage.description}</h4>
                      {status === 'current' && (
                        <Badge variant="default">Current</Badge>
                      )}
                      {status === 'completed' && (
                        <Badge variant="default">
                          <CheckCircle2 className="mr-1 h-3 w-3" />
                          Completed
                        </Badge>
                      )}
                    </div>
                    {stage.role && (
                      <p className="text-sm text-muted-foreground">
                        Role: {stage.role}
                      </p>
                    )}
                    {approval && (
                      <div className="mt-2 p-2 bg-muted rounded text-sm">
                        <div className="flex items-center gap-2">
                          <Badge
                            variant={approval.status === 'APPROVED' ? 'default' : 'destructive'}
                          >
                            {approval.status}
                          </Badge>
                          <span className="text-muted-foreground">
                            {new Date(approval.timestamp).toLocaleDateString()}
                          </span>
                        </div>
                        {approval.comment && (
                          <p className="mt-1 text-muted-foreground">{approval.comment}</p>
                        )}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      </CardContent>
    </Card>
  )
}







